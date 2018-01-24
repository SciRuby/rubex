module Rubex
  module AST
    module Expression
      class Base
        attr_reader :type, :entry
        attr_accessor :typecast

        # In case an expr has to be of a certain type, like a string literal
        #   assigned to a char*, this method will analyse the literal in context
        #   to the target dtype.
        def analyse_for_target_type target_type, local_scope
          analyse_types local_scope
        end

        # If the typecast exists, the typecast is made the overall type of
        # the expression.
        def analyse_types local_scope
          if @typecast
            @typecast.analyse_types(local_scope)
            @type = @typecast.type
          end
        end

        def expression?; true; end

        def has_temp
          @has_temp
        end

        def c_code local_scope
          @typecast ? @typecast.c_code(local_scope) : ""
        end

        def possible_typecast code, local_scope
          @typecast ? @typecast.c_code(local_scope) : ""
        end

        def to_ruby_object
          ToRubyObject.new self
        end

        def from_ruby_object from_node
          FromRubyObject.new self, from_node
        end

        def release_temp local_scope
          local_scope.release_temp(@c_code) if @has_temp
        end

        def allocate_temp local_scope, type
          if @has_temp
            @c_code = local_scope.allocate_temp(type)
          end
        end

        def allocate_temps local_scope
          if @subexprs
            @subexprs.each { |expr| expr.allocate_temp(local_scope, expr.type) }
          end
        end

        def release_temps local_scope
          if @subexprs
            @subexprs.each { |expr| expr.release_temp(local_scope) }
          end
        end

        def generate_evaluation_code(code, local_scope); end

        def generate_disposal_code(code); end

        def generate_assignment_code(rhs, code, local_scope); end

      end
    end # module Expression
  end # module AST
end # module Rubex
