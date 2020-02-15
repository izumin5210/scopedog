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
  end

  after do
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.drop_table :users
  end

  let(:ruby_source) do
    <<~RUBY
      # User represents an user entity of this application.
      class self::User < ActiveRecord::Base
        # @!scoping registered
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
  end
end
