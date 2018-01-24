module Rubex
  module AST
    module Expression
      module Literal
        class Char < Base

          def analyse_for_target_type target_type, local_scope
            if target_type.char?
              @type = Rubex::DataType::Char.new
            elsif target_type.object?
              @type = Rubex::DataType::RubyString.new
              analyse_types local_scope
            else
              raise Rubex::TypeError, "Cannot assign #{target_type} to string."
            end
          end

          def analyse_types local_scope
            @type = Rubex::DataType::RubyString.new unless @type
          end

          def generate_evaluation_code code, local_scope
            if @type.char?
              @c_code = @name
            else
              @c_code = "rb_str_new2(\"#{@name[1]}\")"
            end
          end

          def c_code local_scope
            @c_code
          end
        end # class Char
      end
    end
  end
end
