module Rubex
  module AST
    module Expression
      class Yield < Base
        def initialize(args)
          @args = args
        end

        def analyse_types(local_scope)
          @args = @args.map do |arg|
            arg.analyse_types local_scope
            arg.allocate_temps local_scope
            arg.to_ruby_object
          end
          @args.each do |arg|
            arg.release_temps local_scope
          end
          @subexprs = @args
        end

        def generate_evaluation_code(code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            if !@args.empty?
              code << "rb_yield_values(#{@args.size}, "
              code << (@args.map { |a| a.c_code(local_scope) }.join(',')).to_s
              code << ');'
            else
              code << 'rb_yield(Qnil);'
            end
            code.nl
          end
        end
      end
    end
  end
end
