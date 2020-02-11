require 'yard'
require 'active_record'

module Scopedog
  class ScopeTag < YARD::Tags::Tag
    def initialize(name)
      super('scope', '', nil, name)
    end
  end

  class ScopeHandler < YARD::Handlers::Ruby::MethodHandler
    handles method_call(:scope)
    namespace_only

    process do
      name = call_params[0]
      obj = YARD::CodeObjects::MethodObject.new(namespace, name, :class)
      obj.docstring.add_tag ScopeTag.new(name)
      obj.group = 'Scopes'
      register obj
    end
  end

  class ParanoiaHandler < YARD::Handlers::Ruby::MethodHandler
    handles method_call(:acts_as_paranoid)
    namespace_only

    process do
      [:with_deleted, :without_deleted, :only_deleted].each do |name|
        obj = YARD::CodeObjects::MethodObject.new(namespace, name, :class)
        obj.docstring.add_tag ScopeTag.new(name)
        obj.group = 'Scopes'
        register obj
      end
    end
  end

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

    # @return [Array<YARD::CodeObjects::MethodObject>]
    def scopes
      @scopes ||= yard_obj.meths
        .select { |m| m.scope == :class && m.group == 'Scopes' }
        .map { |m| Scope.new(self, m) }
    end

    # @return [String]
    def default_sql
      ar_class.all.to_sql
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
