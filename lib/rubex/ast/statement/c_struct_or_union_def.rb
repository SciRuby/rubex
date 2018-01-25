module Rubex
  module AST
    module Statement
      class CStructOrUnionDef < Base
        attr_reader :name, :declarations, :type, :kind, :entry, :scope

        def initialize(kind, name, declarations, location)
          super(location)
          @declarations = declarations
          if /struct/.match? kind
            @kind = :struct
          elsif /union/.match? kind
            @kind = :union
          end
          @name = name
        end

        def analyse_statement(outer_scope, extern: false)
          @scope = Rubex::SymbolTable::Scope::StructOrUnion.new(
            @name, outer_scope
          )
          c_name = if extern
                     @kind.to_s + " " + @name
                   else
                     Rubex::TYPE_PREFIX + @scope.klass_name + "_" + @name
                   end
          @type = Rubex::DataType::CStructOrUnion.new(@kind, @name, c_name,
                                                      @scope)

          @declarations.each do |decl|
            decl.analyse_statement @scope, extern: extern
          end
          Rubex::CUSTOM_TYPES[@name] = @type
          @entry = outer_scope.declare_sue(name: @name, c_name: c_name,
                                           type: @type, extern: extern)
        end

        def generate_code(code, local_scope = nil); end

        def rescan_declarations(_local_scope)
          @declarations.each do |decl|
            decl.respond_to?(:rescan_declarations) &&
              decl.rescan_declarations(@scope)
          end
        end
      end
    end
  end
end
