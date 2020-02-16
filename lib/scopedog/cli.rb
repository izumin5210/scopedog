require 'thor'
require 'scopedog'

module Scopedog
  class CLI < Thor
    class_option :verbose, type: :boolean, default: false

    desc "export", "Export ActiveRecord model catalog"
    option :to, type: :string, required: true
    option :dest, type: :hash, default: {}
    def export(path = nil)
      unless path
        if defined? Rails
          path = Rails.root.join('app', 'models', '**', '*.rb').to_s
        else
          path = File.join('lib', '**', '*.rb').to_s
        end
      end

      YARD.parse path

      exporter_class = Scopedog::Exporters.const_get(:"#{options[:to].camelize}Exporter")
      exporter = exporter_class.new(options[:dest])

      Scopedog::RecordClass.all.each do |record_class|
        logger.debug "Export #{record_class.name}"
        exporter.export(record_class)
      end
    end

    no_commands do
      def invoke_command(command, *args)
        prepare
        super
      end
    end

    private

    def prepare
      if defined? Rails
        load './config/application.rb'
        Rails.application.eager_load!
        Scopedog.logger = Rails.logger
      end
      Scopedog.logger.level = options[:verbose] ? Logger::DEBUG : Logger::WARN
    end
  end
end
