module Rubex
  module AST
    module Expression
      class RubyObjectElementRef < AnalysedElementRef
        def analyse_types(local_scope)
          super
          @has_temp = true
          @pos.map! { |a| a.to_ruby_object }
          @pos.allocate_temps local_scope
          @pos.release_temps local_scope
          @subexprs << @pos
        end

        def generate_evaluation_code(code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            @pos.each { |a| a.generate_evaluation_code(code, local_scope) }
            code << "#{@c_code} = rb_funcall(#{@entry.c_name}, rb_intern(\"[]\"), "
            code << @pos.size.to_s
            @pos.each do |p|
              code << ", #{p.c_code(local_scope)}"
            end
            code << ", NULL" if @pos.empty?
            code << ");"
            code.nl
          end
        end

        # Generate code for calls to array_ref inside structs.
        def generate_element_ref_code(expr, code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            @pos.each { |a| a.generate_evaluation_code(code, local_scope) }
            code << "#{@c_code} = rb_funcall(#{expr.c_code(local_scope)}."
            code << "#{@entry.c_name}, rb_intern(\"[]\"), #{@pos.size}"
            @pos.each do |p|
              code << ", #{p.c_code(local_scope)}"
            end
            code << ", NULL" if @pos.empty?
            code << ");"
            code.nl
          end
        end

        def generate_assignment_code(rhs, code, local_scope)
          raise "must specify atleast 1 arg in Object#[]=" if @pos.size < 1
          generate_and_dispose_subexprs(code, local_scope) do
            @pos.each { |a| a.generate_evaluation_code(code, local_scope) }
            code << "rb_funcall(#{@entry.c_name}, rb_intern(\"[]=\"),"
            code << "#{@pos.size + 1}"
            @pos.each do |p|
              code << ", #{p.c_code(local_scope)}"
            end
            code << ", #{rhs.c_code(local_scope)});"
            code.nl
          end
        end
      end
    end
  end
end
