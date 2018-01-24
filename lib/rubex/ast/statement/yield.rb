module Rubex
  module AST
    module Statement
      class Yield < Base
        def initialize(args)
          @args = args
        end

        def analyse_statement(local_scope)
          @args = @args.map do |arg|
            arg.analyse_types local_scope
            arg.allocate_temps local_scope
            arg.allocate_temp local_scope, arg.type
            arg.to_ruby_object
          end

          @args.each do |arg|
            arg.release_temps local_scope
            arg.release_temp local_scope
          end
        end

        def generate_code(code, local_scope)
          @args.each do |a|
            a.generate_evaluation_code code, local_scope
          end

          if !@args.empty?
            code << "rb_yield_values(#{@args.size}, "
            code << (@args.map { |a| a.c_code(local_scope) }.join(',')).to_s
            code << ');'
          else
            code << 'rb_yield(Qnil);'
          end
          code.nl

          @args.each do |a|
            a.generate_disposal_code code
          end
        end
      end
    end
  end
end
