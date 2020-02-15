require 'paranoia'

RSpec.describe Scopedog::RecordClass do
  before { Fixtures.setup(self.class) }
  after { Fixtures.teardown }

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
