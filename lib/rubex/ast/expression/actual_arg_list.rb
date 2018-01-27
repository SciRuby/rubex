module Rubex
  module AST
    module Expression
      class ActualArgList < Base
        include Enumerable
        extend Forwardable

        def_delegators :@args, :empty?, :[]
        
        def each(&block)
          @args.each(&block)
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

        def generate_evaluation_code(code, local_scope)
          generate_and_dispose_subexprs(code, local_scope)
        end
      end
    end
  end
end
