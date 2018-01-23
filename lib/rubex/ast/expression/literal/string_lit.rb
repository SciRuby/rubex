module Rubex
  module AST
    module Expression
      module Literal
        class StringLit < Base

          def analyse_for_target_type target_type, local_scope
            if target_type.char_ptr?
              @type = Rubex::DataType::CStr.new
            elsif target_type.object?
              @type = Rubex::DataType::RubyString.new
              analyse_types local_scope
            else
              raise Rubex::TypeError, "Cannot assign #{target_type} to string."
            end
          end

          def analyse_types local_scope
            @type = Rubex::DataType::RubyString.new unless @type
            @has_temp = 1
          end

          def generate_evaluation_code code, local_scope
            if @type.cstr?
              @c_code = "\"#{@name}\""
            else
              code << "#{@c_code} = rb_str_new2(\"#{@name}\");"
              code.nl
            end
          end

          def generate_disposal_code code
            if @type.object?
              code << "#{@c_code} = 0;"
              code.nl
            end
          end

          def c_code local_scope
            @c_code
          end
        end # class StringLit
      end
    end
  end
end
