module Rubex
  module AST
    module Expression
      class ActualArgList < Base
        include Enumerable
        extend Forwardable

        def_delegators :@args, :empty?, :[], :size, :<<
        
        def each(&block)
          @args.each(&block)
        end

        def map!(&block)
          @args.map!(&block)
        end

        def initialize args
          @args = args
          @subexprs = []
        end
        
        def analyse_types(local_scope)
          @args.each do |arg|
            arg.analyse_types local_scope
            @subexprs << arg
          end
        end

        def analyse_for_target_type(arg_list, local_scope)
          @args.each_with_index do |arg, i|
            arg.analyse_for_target_type arg_list[i].type, local_scope
            @subexprs << arg
          end
        end

        def generate_evaluation_code(code, local_scope)
          @args.each { |a| a.generate_evaluation_code(code, local_scope) }
        end

        def generate_disposal_code(code)
          @args.each { |a| a.generate_disposal_code(code) }
        end
      end
    end
  end
end
