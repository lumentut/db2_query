require 'rails/generators'
# frozen_string_literal: true

require 'fileutils'

module Rails
  class QueryGenerator < Rails::Generators::NamedBase
    attr_reader :queries, :lambdas, :defines

    source_root File.expand_path('../templates', __FILE__)

    class_option :defines, type: :array, default: [], banner: "defs defs"
    class_option :queries, type: :array, default: [], banner: "queries queries"
    class_option :lambdas, type: :array, default: [], banner: "lambdas lambdas"
    class_option :module, type: :string

    def create_query_file
      @method_options = options.slice("defines", "queries", "lambdas")
      @query_methods = @method_options.map {|key, val| val }.flatten
      @module_name = options[:module]
      dir_path = module? ? queries_module_dir_path : queries_dir_path
      generator_path = dir_path.join "#{file_name}.rb"
      FileUtils.mkdir_p(dir_path)
      template "query.erb", generator_path
    end

    private
      def queries_dir_path
        Rails.root.join 'app', 'queries'
      end

      def queries_module_dir_path
        queries_dir_path.join @module_name.underscore
      end

      def module?
        @module_name.present?
      end
      
      def methods?
        methods.any?
      end
  end
end
