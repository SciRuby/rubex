module Rubex
  module AST
    module Expression
      class CommandCall < Base
        def initialize(expr, command, arg_list)
          @expr = expr
          @command = command
          @arg_list = arg_list
        end

        def analyse_types(local_scope)
          @entry = local_scope.find(@command)
          if @expr.nil? # Case for implicit 'self' when a method in the class itself is being called.
            @expr = (@entry && !@entry.extern) ? Expression::Self.new : Expression::Empty.new
          end
          @expr.analyse_types(local_scope)
          analyse_command_type local_scope
          @subexprs = [@expr, @command]
          super
        end

        def generate_evaluation_code(code, local_scope)
          @expr.generate_evaluation_code(code, local_scope)
          @command.generate_evaluation_code code, local_scope
          @c_code = @command.c_code(local_scope)
        end

        def generate_disposal_code(code)
          @expr.generate_disposal_code code
          @command.generate_disposal_code code
        end

        def generate_assignment_code(rhs, code, local_scope)
          generate_evaluation_code code, local_scope
          code << "#{c_code(local_scope)} = #{rhs.c_code(local_scope)};"
          code.nl
        end

        def c_code(local_scope)
          code = super
          code << @c_code
          code
        end

        private

        def struct_member_call?
          ((@expr.type.cptr? && @expr.type.type.struct_or_union?) ||
           @expr.type.struct_or_union?) 
        end

        def ruby_method_call?
          @entry.type.ruby_method?
        end

        def c_function_call?
          @entry && @entry.type.base_type.c_function?
        end

        def raise_call?
          !@entry && @command == "raise"
        end

        def analyse_command_type(local_scope)
          if struct_member_call?
            @command = Expression::StructOrUnionMemberCall.new @expr, @command, @arg_list
          elsif c_function_call?
            @command = Expression::CFunctionCall.new @expr, @command,  @arg_list
          elsif raise_call?
            @command = Expression::Raise.new @arg_list
          else
            @command = Expression::RubyMethodCall.new @expr, @command, @arg_list
          end
          @command.analyse_types local_scope
          @type = @command.type
        end
      end
    end
  end
end
