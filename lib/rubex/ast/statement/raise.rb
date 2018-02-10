module Rubex
  module AST
    module Statement
      class Raise < Base
        def initialize(args)
          @args = args
        end

        def analyse_statement(local_scope)
          @args.analyse_types local_scope
          @args.allocate_temps local_scope
          @args.release_temps local_scope
          unless @args.empty? || @args[0].is_a?(AST::Expression::Name) ||
                 @args[0].is_a?(AST::Expression::Literal::StringLit)
            raise Rubex::TypeMismatchError, "Wrong argument list #{@args.inspect} for raise."
          end
        end

        def generate_code(code, local_scope)
          @args.generate_evaluation_code code, local_scope
          str = ''
          str << 'rb_raise('

          if @args[0].is_a?(AST::Expression::Name)
            str << @args[0].c_code(local_scope) + ','
            args = @args[1..-1]
          else
            str << Rubex::DEFAULT_CLASS_MAPPINGS['RuntimeError'] + ','
            args = @args
          end

          unless args.empty?
            str << "\"#{prepare_format_string(args)}\" ,"
            str << args.map { |arg| (inspected_expr(arg, local_scope)).to_s }.join(',')
          else
            str << '""'
          end
          str << ');'
          code << str
          code.nl
          @args.generate_disposal_code code
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
