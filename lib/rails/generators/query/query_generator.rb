# frozen_string_literal: true

require "rails/generators"
require "fileutils"

module Rails
  module Generators
    class QueryGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("../templates", __FILE__)

      class_option :skip_unit_test, type: :boolean, default: false, desc: "Skip unit test file creation"
      class_option :defines, type: :array, default: [], desc: "Plain query method options"
      class_option :queries, type: :array, default: [], desc: "Query method SQL options"
      class_option :lambdas, type: :array, default: [], desc: "Query method with callable args"

      def create_query_file
        template "query.rb", File.join("app/queries", class_path, "#{file_name}_query.rb")
      end

      def create_query_definitions_file
        template "query_definitions.rb", File.join("app/queries/definitions", class_path, "#{file_name}_query_definitions.rb")
      end

      def create_query_test_file
        unless options[:skip_unit_test]
          template "unit_test.rb", File.join("test/queries", class_path, "#{file_name}_query_test.rb")
        end
      end

      private
        def assign_names!(name)
          super(name)
          @method_options = options.slice("defines", "queries", "lambdas")
          @query_methods = @method_options.map { |key, val| val }.flatten
        end

        def query_class_name
          "#{file_name.camelize}Query"
        end

        def namespaced_query?
          !class_path.empty?
        end

        def namespaced_names
          class_path
        end

        def namespaced_content(content)
          namespaced_names.reverse_each do |namespace_name|
            content = "module #{namespace_name.camelize}\n#{indent(content)}\nend"
          end
          content
        end

        def module_namespacing(&block)
          content = capture(&block)
          content = namespaced_content(content) if namespaced_query?
          concat(content)
        end

        def module_definitions_namespacing(&block)
          content = capture(&block)
          content = namespaced_content(content) if namespaced_query?
          definitions_namespace_content = "module Definitions\n#{indent(content)}\nend"
          concat(definitions_namespace_content)
        end
    end
  end
end
