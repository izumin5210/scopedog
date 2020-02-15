require 'tmpdir'

RSpec.describe Scopedog::Exporters::MarkdownExporter do
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

  let(:exporter) { Scopedog::Exporters::MarkdownExporter.new(dir: dir) }
  let(:dir) { 'doc/models' }

  describe '#export' do
    def in_tmp(&block)
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          block.call
        end
      end
    end

    it "exports a markdown document" do
      content =
        in_tmp do
          exporter.export(user_record_class)
          File.read("doc/models/user.md")
        end
      expect(content).to match_snapshot
    end

    context 'when the record_class is inside namespace' do
      it "exports a markdown document" do
        content =
          in_tmp do
            exporter.export(admin_log_record_class)
            File.read("doc/models/admin/log.md")
          end
        expect(content).to match_snapshot
      end
    end
  end
end
