namespace :scopedog do
  namespace :export do
    desc "Export ActiveRecord models as markdown"
    task markdown: :environment do
      path =
        if defined? Rails
          Rails.root.join('app', 'models', '**', '*.rb').to_s
        else
          File.join('lib', '**', '*.rb').to_s
        end

      Scopedog.logger.debug "Parsing #{path}"
      YARD.parse path

      record_classes = Scopedog::RecordClass.all
      Scopedog.logger.debug "#{record_classes.size} record classes are found"

      exporter = Scopedog::Exporters::MarkdownExporter.new(dir: 'docs')

      record_classes.each do |record_class|
        Scopedog.logger.debug "Export #{record_class.name}"
        exporter.export(record_class)
      end
    end
  end
end
