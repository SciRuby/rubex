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
            Rubex::TYPE_MAPPINGS[a].new || Rubex::CUSTOM_TYPES[a]
          end
          ret_t = Rubex::TYPE_MAPPINGS[@type].new || Rubex::CUSTOM_TYPES[@type]
          @type = Rubex::DataType::CFunction.new @name, @args, ret_t
          local_scope.declare_cfunction self
        end
      end # class CFunctionDecl
    end # class CBindings
  end # module AST
end # module Rubex
