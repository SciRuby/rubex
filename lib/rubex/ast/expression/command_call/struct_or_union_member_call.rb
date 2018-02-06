module Rubex
  module AST
    module Expression
      class StructOrUnionMemberCall < CommandCall
        def analyse_types(local_scope)
          scope = @expr.type.base_type.scope

          if @command.is_a? String
            @command = Expression::Name.new @command
            @command.analyse_types scope
          elsif @command.is_a? Rubex::AST::Expression::ElementRef
            @command = Expression::ElementRefMemberCall.new @expr, @command, @arg_list
            @command.analyse_types local_scope, scope
          end
          @has_temp = @command.has_temp
          @type = @command.type
          @subexprs = [@expr, @command]
        end

        def generate_evaluation_code code, local_scope
          @expr.generate_evaluation_code code, local_scope
          @command.generate_evaluation_code code, local_scope
          @c_code =
            if @command.has_temp
              @command.c_code(local_scope)
            else
              op = @expr.type.cptr? ? '->' : '.'
              "#{@expr.c_code(local_scope)}#{op}#{@command.c_code(local_scope)}"
            end
        end

        def c_code(_local_scope)
          @c_code
        end
      end
    end
  end
end
