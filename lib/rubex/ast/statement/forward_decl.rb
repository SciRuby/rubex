module Rubex
  module AST
    module Statement
      class ForwardDecl < Base
        def initialize(kind, name, location)
          super(location)
          @name = name
          if /struct/.match? kind
            @kind = :struct
          elsif /union/.match? kind
            @kind = :union
          end
          Rubex::CUSTOM_TYPES[@name] = @name
        end

        def analyse_statement(local_scope, extern: false)
          @c_name = Rubex::TYPE_PREFIX + local_scope.klass_name + '_' + @name
          @type = Rubex::DataType::TypeDef.new("#{@kind} #{@name}", @c_name, @type)
          local_scope.declare_type type: @type, extern: extern
        end

        def rescan_declarations(_local_scope)
          @type = Rubex::DataType::TypeDef.new("#{@kind} #{@name}", @c_name,
                                               Rubex::CUSTOM_TYPES[@name])
        end

        def generate_code(code, local_scope); end
      end
    end
  end
end
