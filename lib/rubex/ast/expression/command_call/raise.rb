module Rubex
  module AST
    module Expression
      class Raise < CommandCall
        def initialize(args)
          @args = args
        end

        def analyse_types(local_scope)
          @args.analyse_types local_scope
          @args.allocate_temps local_scope
          unless @args.empty? || @args[0].is_a?(AST::Expression::Name) ||
                 @args[0].is_a?(AST::Expression::Literal::StringLit)
            raise Rubex::TypeMismatchError, "Wrong argument list #{@args.inspect} for raise."
          end
          @subexprs = [@args]
          @args.release_temps local_scope
        end

        def generate_evaluation_code(code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            @c_code = ''
            @c_code << 'rb_raise('

            if @args[0].is_a?(AST::Expression::Name)
              @c_code << @args[0].c_code(local_scope) + ','
              args = @args[1..-1]
            else
              @c_code << Rubex::DEFAULT_CLASS_MAPPINGS['RuntimeError'] + ','
              args = @args
            end

            unless args.empty?
              @c_code << "\"#{prepare_format_string(args)}\" ,"
              @c_code << args.map { |arg| (inspected_expr(arg, local_scope)).to_s }.join(',')
            else
              @c_code << '""'
            end
            @c_code << ');'
          end
        end

        def generate_disposal_code(code); end

        def c_code(_local_scope)
          super + @c_code
        end

        private

        def prepare_format_string(args)
          format_string = ''
          args.each do |expr|
            format_string << expr.type.p_formatter
          end

          format_string
        end

        def inspected_expr(expr, local_scope)
          obj = expr.c_code(local_scope)
          if expr.type.object?
            "RSTRING_PTR(rb_funcall(#{obj}, rb_intern(\"inspect\"), 0, NULL))"
          else
            obj
          end
        end
      end
    end
  end
end
