require 'active_record'

module Scopedog
  # @attr_reader yard_obj [YARD::CodeObjects::ClassObject]
  # @attr_reader ar_class [Class<ActiveRecord::Base>]
  class RecordClass
    attr_reader :yard_obj, :ar_class

    # @param docs [Array<YARD::CodeObjects::Base>]
    # @return [Array<RecordClass>]
    def self.all(docs: YARD::Registry.all, root_const: Object)
      docs
        .select { |d| d.type == :class }
        .map { |d| [d, root_const.const_get(d.name)] }
        .select { |(_, c)| c.ancestors.include?(ActiveRecord::Base) && !c.abstract_class? }
        .map { |d, c| RecordClass.new(d, c) }
    end

    # @param yard_obj [YARD::CodeObjects::ClassObject]
    # @param ar_class [Class<ActiveRecord::Base>]
    def initialize(yard_obj, ar_class)
      @yard_obj = yard_obj
      @ar_class = ar_class
    end

    # @return [String]
    def name
      yard_obj.name
    end

    # @return [String]
    def docstring
      yard_obj.docstring
    end

    # @return [String]
    def table_name
      ar_class.table_name
    end

    # @return [Array<YARD::CodeObjects::MethodObject>]
    def scopes
      @scopes ||= yard_obj.meths
        .select { |m| m.has_tag?(:scoping) }
        .map { |m| Scope.new(self, m) }
    end

    # @return [String]
    def default_sql
      ar_class.all.to_sql
    end

    # @return [String]
    def unscoped_sql
      ar_class.all.unscoped.to_sql
    end

    # @attr_reader record_class [Scopedog::RecordClass]
    # @attr_reader yard_obj [YARD::CodeObjects::MethodObject]
    class Scope
      attr_reader :yard_obj, :record_class

      # @param record_class [Scopedog::RecordClass]
      # @param meth [YARD::CodeObjects::MethodObject]
      def initialize(record_class, yard_obj)
        @record_class = record_class
        @yard_obj = yard_obj
      end

      # @return [String]
      def name
        yard_obj.name
      end

      # @return [String]
      def docstring
        yard_obj.docstring
      end

      # @return [String]
      def sql
        record_class.ar_class.send(name).to_sql
      end
    end
  end
end
