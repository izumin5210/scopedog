module Scopedog::Exporters
  class MarkdownExporter
    # @param opts [Hash]
    # @option opts [String] :dir
    def initialize(opts = {})
      @dir = opts[:dir]
    end

    # @param record_class [Scopedog::RecordClass]
    # @param dest [Hash]
    # @option dest [String] :prefix
    # @option dest [String] :name
    def export(record_class, destination = {})
      name = destination[:name] || record_class.name.to_s.underscore
      name = "#{name}.md" unless File.extname(name) == '.md'

      dir = @dir
      dir = File.join(dir, destination[:prefix]) if destination[:prefix]

      if name.include? '/'
        name, prefix = name.split('/').yield_self { |p| [p[-1], p[0..-2]] }
        dir = File.join(dir, prefix)
      end

      FileUtils.mkdir_p(dir) unless File.exists?(dir)

      File.open(File.join(dir, name), 'w') do |f|
        f.puts <<~MARKDOWN
          # #{record_class.name}
          #{record_class.docstring}

          ```sql
          -- default scope
          #{record_class.default_sql}
          ```
        MARKDOWN

        unless record_class.scopes.empty?
          f.puts
          f.puts "## Scopes"

          record_class.scopes.each do |s|
            f.puts
            f.puts <<~MARKDOWN
              ### `#{s.name}`
              #{s.docstring}

              ```sql
              #{s.sql}
              ```
            MARKDOWN
          end
        end
      end
    end
  end
end
