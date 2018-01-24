module Rubex
  module AST
    module Expression
      class CommandCall < Base
        def initialize(expr, command, arg_list)
          @expr = expr
          @command = command
          @arg_list = arg_list
          @subexprs = []
        end

        def analyse_types(local_scope)
          analyse_arg_list_and_add_to_subexprs local_scope
          @entry = local_scope.find(@command)
          if @expr.nil? # Case for implicit 'self' when a method in the class itself is being called.
            @expr = Expression::Self.new if @entry && !@entry.extern
          else
            @expr.analyse_types(local_scope)
            @expr.allocate_temps local_scope
            @expr.allocate_temp local_scope, @expr.type
          end
          add_as_ruby_method_to_symtab(local_scope) unless @entry
          analyse_command_type local_scope
          super
        end

        def generate_evaluation_code(code, local_scope)
          @c_code = ''
          @arg_list.each do |arg|
            arg.generate_evaluation_code code, local_scope
          end
          @expr&.generate_evaluation_code(code, local_scope)
          @command.generate_evaluation_code code, local_scope
          @c_code << @command.c_code(local_scope)
        end

        def generate_disposal_code(code)
          @expr&.generate_disposal_code(code)
          @arg_list.each do |arg|
            arg.generate_disposal_code code
          end
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

        def analyse_arg_list_and_add_to_subexprs(local_scope)
          @arg_list.each do |arg|
            arg.analyse_types local_scope
            @subexprs << arg
          end
        end

        def add_as_ruby_method_to_symtab(local_scope)
          @entry = local_scope.add_ruby_method(
            name: @command,
            c_name: @command,
            extern: true,
            arg_list: @arg_list,
            scope: nil
          )
        end

        def struct_member_call?
          @expr && ((@expr.type.cptr? && @expr.type.type.struct_or_union?) ||
          @expr.type.struct_or_union?)
        end

        def ruby_method_call?
          @entry.type.ruby_method?
        end

        def c_function_call?
          @entry.type.base_type.c_function?
        end

        def allocate_and_release_temps(local_scope)
          @command.allocate_temps local_scope
          @command.allocate_temp local_scope, @type
          @command.release_temps local_scope
          @command.release_temp local_scope
        end

        def analyse_command_type(local_scope)
          if struct_member_call?
            @command = Expression::StructOrUnionMemberCall.new @expr, @command, @arg_list
          elsif ruby_method_call?
            @command = Expression::RubyMethodCall.new @expr, @command, @arg_list
          elsif c_function_call?
            @command = Expression::CFunctionCall.new @expr, @command,  @arg_list
          end
          @command.analyse_types local_scope
          @type = @command.type
          allocate_and_release_temps local_scope
        end
      end # class CommandCall
    end
  end
end
