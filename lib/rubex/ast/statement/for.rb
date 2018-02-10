module Rubex
  module AST
    module Statement
      class For < Base
        def initialize(left_expr, left_op, middle, right_op, right_expr, statements, location)
          super(location)
          @left_expr = left_expr
          @left_op = left_op
          @middle = middle
          @right_op = right_op
          @right_expr = right_expr
          @statements = statements
        end

        def analyse_statement(local_scope)
          @left_expr.analyse_types local_scope
          @right_expr.analyse_types local_scope

          [@left_expr, @right_expr].each do |e|
            e.allocate_temps local_scope
          end
          [@left_expr, @right_expr].each do |e|
            e.release_temps local_scope
          end

          @middle = local_scope[@middle] # middle will not be an expr.
          @statements.each do |stat|
            stat.analyse_statement local_scope
          end
        end

        def generate_code(code, local_scope)
          code << for_loop_header(code, local_scope)
          code.block do
            @statements.each do |stat|
              stat.generate_code code, local_scope
            end
          end
          @left_expr.generate_disposal_code code
          @right_expr.generate_disposal_code code
        end

        private

        def for_loop_header(code, local_scope)
          @left_expr.generate_evaluation_code code, local_scope
          @right_expr.generate_evaluation_code code, local_scope
          for_stmt = ''
          for_stmt << "for (#{@middle.c_name} = #{@left_expr.c_code(local_scope)}"

          if @left_op == '<'
            for_stmt << ' + 1'
          elsif @left_op == '>'
            for_stmt << ' - 1'
          end

          for_stmt << "; #{@middle.c_name} #{@right_op} #{@right_expr.c_code(local_scope)}; "
          for_stmt << (@middle.c_name).to_s

          if ['>', '>='].include? @right_op
            for_stmt << '--'
          elsif ['<', '<='].include? @right_op
            for_stmt << '++'
          end

          for_stmt << ')'

          for_stmt
        end
      end
    end
  end
end
