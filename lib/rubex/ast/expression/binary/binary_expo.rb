module Rubex
  module AST
    module Expression
      class BinaryExpo < Binary
        def analyse_types(local_scope)
          @left.analyse_types local_scope
          @right.analyse_types local_scope
          if type_of(@left).object? || type_of(@right).object?            
            @left = @left.to_ruby_object
            @right = @right.to_ruby_object
            @subexprs << @left
            @subexprs << @right
          else
            @type = Rubex::DataType::F64.new
          end

        end

        def generate_evaluation_code code, local_scope
          generate_and_dispose_subexprs(code, local_scope) do
            if @type.object?
              code << "#{@c_code} = rb_funcall(#{@left.c_code(local_scope)}," +
                "rb_intern(\"#{@operator}\")," +
                "1, #{@right.c_code(local_scope)});"
              code.nl
            else
              @c_code = "( pow(#{@left.c_code(local_scope)}, #{@right.c_code(local_scope)}) )"
            end
          end
        end
      end
    end
  end
end
