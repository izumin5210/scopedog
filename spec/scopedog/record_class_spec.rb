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
        acts_as_paranoid column: :deleted, sentinel_value: false

        # Lists registered users.
        scope :registered, -> { where(registered: true) }
      end
    RUBY
  end

  before do
    self.class.instance_eval ruby_source
    YARD.parse_string ruby_source
  end
  after { YARD::Registry.clear }

  let(:record_classes) { Scopedog::RecordClass.all(root_const: self.class) }
  let(:user_record_class) { record_classes[0] }

  it { expect(record_classes.size).to eq 1 }

  describe '#default_sql' do
    it "includes default scope" do
      expect(user_record_class.default_sql).to match_snapshot
    end
  end

  describe '#scopes' do
    let(:scopes) { user_record_class.scopes }

    [
      { summary: 'simple scope', names: [:registered] },
      { summary: 'defined by paranoia gem', names: [:only_deleted, :without_deleted, :with_deleted] },
    ].each do |summary:, names:|
      context summary do
        names.each do |name|
          describe "#sql for #{name} scope" do
            it "returns a SQL string defined in a scope" do
              scope = scopes.find { |s| s.name == name }
              expect(scope).to be_present
              expect(scope.sql).to match_snapshot
            end
          end
        end
      end
    end
  end
end
