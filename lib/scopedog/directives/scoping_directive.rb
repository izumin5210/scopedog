module Scopedog::Directives
  class ScopingDirective < Base
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
end
