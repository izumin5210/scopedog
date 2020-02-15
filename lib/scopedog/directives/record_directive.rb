module Scopedog::Directives
  class RecordDirective < Base
    # @!override YARD::Tags::Directive#call
    def call
      parser.tags << YARD::Tags::Tag.new(:record, '', nil, tag.name || parser.object.name)
    end
  end
end
