module Rubex
  module AST
    class CBindings
      attr_reader :lib, :declarations

      def initialize lib, declarations
        @lib, @declarations = lib, declarations
      end

      def analyse_statements local_scope
        @declarations.each do |stat|
          stat.analyse_statement local_scope, extern: true
        end
        local_scope.include_files.push @lib
      end

      def generate_code code

      end

      class CFunctionDecl
        include Rubex::AST::Statement
        attr_reader :type, :name, :args, :extern

        def initialize type, name, args
          @type, @name, @args = type, name, args
        end

        def analyse_statement local_scope, extern: false
          @extern = extern
          @args.map! do |a|
            determine_dtype a
          end
          @type = determine_dtype @type
          local_scope.declare_cfunction self
        end

      private

        def determine_dtype dtype_or_ptr
          if dtype_or_ptr[-1] == "*"
            Rubex::DataType::CPtr.new simple_dtype(dtype_or_ptr[0...-1])
          else
            simple_dtype(dtype_or_ptr)
          end
        end

        def simple_dtype dtype
          Rubex::CUSTOM_TYPES[dtype] || Rubex::TYPE_MAPPINGS[dtype].new
        end
      end # class CFunctionDecl
    end # class CBindings
  end # module AST
end # module Rubex
