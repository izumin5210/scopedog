require 'yard'
require 'active_record'

module Scopedog
  # @abstract
  class BaseDirective < YARD::Tags::Directive
    class << self
      attr_accessor :abstract_class

      def abstract_class?
        defined?(@abstract_class) && @abstraact_class == true
      end

      def inherited(klass)
        return if klass.abstract_class?

        YARD::Tags::Library.define_directive klass.directive_name, :with_name, klass
      end

      def directive_name
        name.demodulize.underscore.gsub(/_directive$/, '')
      end
    end

    self.abstract_class = true

    # @!override YARD::Tags::Directive#after_parse
    def call; end

    protected

    def add_method!(name = nil, tags: [])
      name = handler.call_params.first if name.nil?

      obj = create_method_object(name)
      visibility = parser.state.visibility || handler.visibility

      handler.register_file_info(obj)
      handler.register_source(obj)
      handler.register_visibility(obj, visibility)
      handler.register_group(obj)
      handler.register_module_function(obj)

      old_obj = parser.object
      parser.object = obj
      parser.post_process
      parser.object = old_obj
      obj
    end

    # @return [YARD::CodeObjects::MethodObject]
    def create_method_object(name)
      scope = parser.state.scope || handler.scope
      ns = YARD::CodeObjects::NamespaceObject === object ? object : handler.namespace
      signature = "def #{tag.name}"

      YARD::CodeObjects::MethodObject.new(ns, name, scope).tap do |obj|
        obj.signature = signature
        obj.parameters = YARD::Tags::OverloadTag.new(:overload, signature).parameters
        obj.docstring = YARD::Docstring.new!(parser.text, parser.tags, obj, parser.raw_text, parser.reference)
      end
    end
  end

  class ScopingDirective < BaseDirective
    # @!override YARD::Tags::Directive#after_parse
    def after_parse
      parser.state.scope = :class
      add_method!
    end

    protected

    # @!override Scopedog::BaseDirective#create_method_object
    def create_method_object(name)
      super.tap do |obj|
        obj.group = 'Scopes'
        obj.add_tag YARD::Tags::Tag.new(:scoping, '', nil, handler.call_params.first)
      end
    end
  end

  class ParanoidDirective < BaseDirective
    # @!override YARD::Tags::Directive#after_parse
    def after_parse
      parser.state.scope = :class
      name = tag.name

      add_method! "only_#{name}"
      add_method! "with_#{name}"
      add_method! "without_#{name}"
    end

    protected

    # @!override Scopedog::BaseDirective#create_method_object
    def create_method_object(name)
      super.tap do |obj|
        obj.group = 'Scopes'
        obj.add_tag YARD::Tags::Tag.new(:scoping, '', nil, name)
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
        .select { |m| m.has_tag?(:scoping) }
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
