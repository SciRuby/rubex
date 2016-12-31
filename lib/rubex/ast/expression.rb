module Rubex
  module AST
    module Expression

      # Stub for making certain subclasses of Expression not needed statement analysis.
      def analyse_statement local_scope
        nil
      end

      class Binary
        include Rubex::AST::Expression
        include Rubex::Helpers::NodeTypeMethods

        attr_reader :operator
        attr_accessor :left, :right
        # Final return type of expression
        attr_accessor :type

        def initialize left, operator, right
          @left, @operator, @right = left, operator, right
        end

        def analyse_statement local_scope
          analyse_left_and_right_nodes local_scope, self
          analyse_return_type local_scope, self
        end

        def c_code local_scope
          code = ""
          recursive_generate_code(local_scope, code, self)
          code
        end

        def expression?; true; end

        def == other
          self.class == other.class && @type  == other.type &&
          @left == other.left  && @right == other.right &&
          @operator == other.operator
        end

      private

        def analyse_left_and_right_nodes local_scope, tree
          if tree.respond_to?(:left)
            analyse_left_and_right_nodes local_scope, tree.left
              if local_scope.has_entry?(tree.left)
                tree.left = local_scope[tree.left]
              end
              if local_scope.has_entry?(tree.right)
                tree.right = local_scope[tree.right]
              end
            analyse_left_and_right_nodes local_scope, tree.right
          end
        end

        def analyse_return_type local_scope, tree
          if tree.respond_to? :left
            analyse_return_type local_scope, tree.left
            analyse_return_type local_scope, tree.right

            if ['==', '<', '>', '<=', '>='].include? tree.operator
              tree.type = Rubex::DataType::Boolean.new
            else
              tree.type = Rubex::Helpers.result_type_for(
                     tree.left.type, tree.right.type)
            end
          end
        end

        def recursive_generate_code local_scope, code, tree
          if tree.respond_to? :left
            recursive_generate_code local_scope, code, tree.left
            code << "( #{tree.left.c_code(local_scope)}" unless tree.left.respond_to?(:left)
            code << " #{tree.operator} "
            code << "#{tree.right.c_code(local_scope)} )" unless tree.right.respond_to?(:right)
            recursive_generate_code local_scope, code, tree.right
          end
        end
      end # class Binary

      class ArrayRef
        include Rubex::AST::Expression
        attr_reader :name, :pos, :type

        def initialize name, pos
          @name, @pos = name, pos
        end

        def analyse_statement local_scope
          @type = local_scope[@name].type
        end

        def c_code local_scope
          "#{local_scope[name].c_name}[#{pos}]"
        end
      end # class ArrayRef

      module Literal
        include Rubex::AST::Expression
        attr_reader :literal

        def initialize literal
          @literal = literal
        end

        def c_code local_scope
          @literal
        end

        def c_name
          @literal
        end

        def literal?; true; end

        def == other
          self.class == other.class && @literal == other.literal
        end

        class Double
          include Rubex::AST::Expression::Literal

          def type
            Rubex::DataType::F64.new
          end
        end

        class Int
          include Rubex::AST::Expression::Literal

          def type
            Rubex::DataType::Int.new
          end
        end

        # class Str; include Rubex::AST::Expression::Literal;  end

        class Char
          include Rubex::AST::Expression::Literal

          def type
            Rubex::DataType::Char.new
          end
        end # class Char
      end # module Literal

      # Singular name node with no sub expressions.
      class Name
        include Rubex::AST::Expression
        attr_reader :value, :entry, :type

        def initialize value
          @value = value
        end

        def analyse_statement local_scope
          @entry = local_scope[@value]
          @type = @entry.type
        end

        def c_code local_scope
          @entry.c_name
        end
      end
    end # module Expression
  end # module AST
end # module Rubex
