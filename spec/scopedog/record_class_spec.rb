require 'paranoia'

RSpec.describe Scopedog::RecordClass do
  before do
    ActiveRecord::Base.establish_connection(
      adapter:  "sqlite3",
      database: ":memory:",
    )
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.create_table :users do |t|
      t.string :name
      t.boolean :registered
      t.boolean :deleted
    end
    m.create_table :admin_logs do |t|
      t.integer :user_id
      t.boolean :checked
      t.string :data
      t.datetime :created_at
    end
  end

  after do
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.drop_table :users
  end

  let(:ruby_source) do
    <<~RUBY
      class self::ApplicationRecord < ActiveRecord::Base
        self.abstract_class = true
      end

      class self::User < self::ApplicationRecord
        # @!paranoid deleted
        acts_as_paranoid column: :deleted, sentinel_value: false

        # @!scoping registered
        # Lists registered users.
        scope :registered, -> { where(registered: true) }
      end

      module self::Admin
        def self.table_name_prefix
          'admin_'
        end
      end

      class self::Admin::Log < self::ApplicationRecord
        # @!scoping unchecked
        # List operation logs that has not checked yet
        scope :unchecked, -> { where(checked: false) }
      end
    RUBY
  end

  before do
    self.class.instance_eval ruby_source
    YARD.parse_string ruby_source.gsub(/self::/, "")
  end
  after { YARD::Registry.clear }

  let(:record_classes) { Scopedog::RecordClass.all(root_const: self.class) }
  let(:user_record_class) { record_classes.find { |rc| rc.table_name == 'users' } }
  let(:admin_log_record_class) { record_classes.find { |rc| rc.table_name == 'admin_logs' } }

  it { expect(record_classes.size).to eq 2 }

  describe '#default_sql' do
    it "includes default scope" do
      expect(user_record_class.default_sql).to match_snapshot
    end
  end

  describe '#unscoped_sql' do
    it "does not include default scope" do
      expect(user_record_class.unscoped_sql).to match_snapshot
    end
  end

  describe '#scopes' do
    [
      { summary: 'simple scope', record_class: :user, names: [:registered] },
      { summary: 'defined by paranoia gem', record_class: :user, names: [:only_deleted, :without_deleted, :with_deleted] },
      { summary: 'namespaced record class', record_class: :admin_log, names: [:unchecked] },
    ].each do |summary:, record_class:, names:|
      context summary do
        names.each do |name|
          describe "#sql for #{name} scope" do
            it "returns a SQL string defined in a scope" do
              scope = send(:"#{record_class}_record_class").scopes.find { |s| s.name == name }
              expect(scope).to be_present
              expect(scope.sql).to match_snapshot
            end
          end
        end
      end
    end
  end
end
