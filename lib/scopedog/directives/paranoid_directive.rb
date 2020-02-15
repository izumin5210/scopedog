module Scopedog::Directives
  class ParanoidDirective < Base
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
end
