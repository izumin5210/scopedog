require 'tmpdir'

RSpec.describe Scopedog::Exporters::MarkdownExporter do
  before { Fixtures.setup(self.class) }
  after { Fixtures.teardown }

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
