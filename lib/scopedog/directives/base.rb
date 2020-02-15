require 'active_support/core_ext/string/inflections'

module Scopedog::Directives
  # @abstract
  class Base < YARD::Tags::Directive
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
end
