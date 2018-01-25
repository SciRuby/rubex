module Rubex
  module AST
    module Expression
      module Literal
        class Char < Base
          def analyse_for_target_type(target_type, local_scope)
            if target_type.char?
              @type = Rubex::DataType::Char.new
            elsif target_type.object?
              @type = Rubex::DataType::RubyString.new
              analyse_types local_scope
            else
              raise Rubex::TypeError, "Cannot assign #{target_type} to string."
            end
          end

          def analyse_types(_local_scope)
            @type ||= Rubex::DataType::RubyString.new
          end

          def generate_evaluation_code(_code, _local_scope)
            @c_code = if @type.char?
                        @name
                      else
                        "rb_str_new2(\"#{@name[1]}\")"
                      end
          end

          def c_code(_local_scope)
            @c_code
          end
        end
      end
    end
  end
end
