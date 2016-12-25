module Rubex
  module AST
    module Expression
      class Binary
        include Rubex::AST::Expression

        attr_reader   :left, :operator, :right
        attr_accessor :return_type

        def initialize left, operator, right
          @left, @operator, @right = left, operator, right
        end

        def analyse_statement local_scope
          puts "#{self.inspect}"
          analyse_return_type local_scope, self
        end

        def c_code local_scope
          code = ""
          recursive_generate_code(local_scope, code, self)
          code
        end

      private

        def analyse_return_type local_scope, tree
          if tree.respond_to? :left
            analyse_return_type local_scope, tree.left

            if tree.left.is_a?(Rubex::AST::Expression) &&
               tree.right.is_a?(Rubex::AST::Expression)

              tree.return_type =
               Rubex::Helpers.result_type_for(
                 tree.left.return_type, tree.right.return_type)
            else
              left_type = type_for local_scope, left
              right_type = type_for local_scope, right

              tree.return_type =
                Rubex::Helpers.result_type_for left_type, right_type
            end

            analyse_return_type local_scope, tree.right
          end
        end

        def type_for local_scope, node
          t = nil
          if local_scope.has_entry? node
            t = local_scope[node].type
          else
            Rubex::LITERAL_MAPPINGS.each do |regex, type|
              puts "#{node.inspect}"
              if regex.match(node)
                t = type.new
                break
              end
            end
          end

          raise "Cannot identify type of literal #{node}." if t.nil?
          t
        end

        def recursive_generate_code local_scope, code, tree
          if tree.respond_to? :left
            recursive_generate_code local_scope, code, tree.left
            if tree.left.is_a?(Rubex::AST::Expression) &&
               tree.right.is_a?(Rubex::AST::Expression)
              code << "#{tree.operator}"
            else
              str = "("
              if local_scope.has_entry? tree.left
                l = local_scope[tree.left]
                str << "#{l.c_name} "
              else
                str << "#{tree.left}"
              end

              str << " #{tree.operator} "

              if local_scope.has_entry? tree.right
                r = local_scope[tree.right]
                str << "#{r.c_name}"
              else
                str << "#{tree.right}"
              end
              str << ")"
              code << str
            end
            recursive_generate_code local_scope, code, tree.right
          end
        end
      end
    end
  end
end
