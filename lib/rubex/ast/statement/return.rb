module Rubex
  module AST
    module Statement
      class Return < Base
        def initialize(expression, location)
          super(location)
          @expression = expression
        end

        def analyse_statement(local_scope)
          unless @expression
            if local_scope.type.ruby_method?
              @expression = Rubex::AST::Expression::Literal::Nil.new 'Qnil'
            elsif local_scope.type.c_function?
              @expression = Rubex::AST::Expression::Empty.new
            end # FIXME: print a warning for type mismatch if none of above
          end

          @expression.analyse_types local_scope
          @expression.allocate_temps local_scope
          @expression.allocate_temp local_scope, @expression.type
          @expression.release_temps local_scope
          @expression.release_temp local_scope
          t = @expression.type

          @type =
            if t.c_function? || t.alias_type?
              t.type
            else
              t
            end
          @expression = @expression.to_ruby_object if local_scope.type.type.object?

          # TODO: Raise error if type as inferred from the
          # is not compatible with the return statement type.
        end

        def generate_code(code, local_scope)
          super
          @expression.generate_evaluation_code code, local_scope
          code << "return #{@expression.c_code(local_scope)};"
          code.nl
        end
      end
    end
  end
end
