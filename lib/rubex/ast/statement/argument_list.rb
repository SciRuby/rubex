module Rubex
  module AST
    module Statement
      # This node is used for both formal and actual arguments of functions/methods.
      class ArgumentList < Base
        include Enumerable

        # args - [ArgDeclaration]
        attr_reader :args

        def each(&block)
          @args.each(&block)
        end

        def map!(&block)
          @args.map!(&block)
        end

        def pop
          @args.pop
        end

        def initialize(args)
          @args = args
        end

        def analyse_statement(local_scope, extern: false)
          @args.each do |arg|
            arg.analyse_types(local_scope, extern: extern)
          end
        end

        def push(arg)
          @args << arg
        end

        def <<(arg)
          push arg
        end

        def ==(other)
          self.class == other.class && @args == other.args
        end

        def size
          @args.size
        end

        def empty?
          @args.empty?
        end

        def [](idx)
          @args[idx]
        end
      end
    end
  end
end
