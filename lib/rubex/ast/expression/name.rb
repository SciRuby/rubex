module Rubex
  module AST
    module Expression

      # Singular name node with no sub expressions.
      class Name < Base
        attr_reader :name, :entry, :type

        def initialize(name)
          @name = name
        end

        # Used when the node is a LHS of an assign statement.
        def analyse_declaration rhs, local_scope
          @entry = local_scope.find @name
          unless @entry
            local_scope.add_ruby_obj(name: @name, c_name: Rubex::VAR_PREFIX + @name, value: @rhs)
            @entry = local_scope[@name]
          end
          @type = @entry.type
        end

        def analyse_for_target_type(target_type, local_scope)
          @entry = local_scope.find @name

          if @entry && @entry.type.c_function? && target_type.c_function_ptr?
            @type = @entry.type
          else
            analyse_types local_scope
          end
        end

        # Analyse a Name node. This can either be a variable name or a method call
        #   without parenthesis. Code in this method that creates a RubyMethodCall
        #   node primarily exists because in Ruby methods without arguments can
        #   be called without parentheses. These names can potentially be Ruby
        #   methods that are not visible to Rubex, but are present in the Ruby
        #   run time. For example, a program like this:
        #
        #     def foo
        #       bar
        #      #^^^ this is a name node
        #     end

        def analyse_types(local_scope)
          @entry = local_scope.find @name
          unless @entry
            if ruby_constant?
              analyse_as_ruby_constant local_scope
            else
              add_as_ruby_method_to_scope local_scope
            end
          end
          analyse_as_ruby_method(local_scope) if @entry.type.ruby_method?
          assign_type_based_on_whether_wrapped_type
          super
        end

        def generate_evaluation_code(code, local_scope)
          if @name.respond_to? :generate_evaluation_code
            @name.generate_evaluation_code code, local_scope
          end
        end

        def generate_disposal_code(code)
          if @name.respond_to? :generate_disposal_code
            @name.generate_disposal_code code
          end
        end

        def generate_assignment_code(rhs, code, local_scope)
          code << "#{c_code(local_scope)} = #{rhs.c_code(local_scope)};"
          code.nl
          rhs.generate_disposal_code code
        end

        def c_code(local_scope)
          code = super
          code << if @name.is_a?(Rubex::AST::Expression::Base)
            @name.c_code(local_scope)
          else
            @entry.c_name
          end

          code
        end

        private

        def ruby_constant?
          @name[0].match /[A-Z]/
        end

        def analyse_as_ruby_constant(local_scope)
          @name = Expression::RubyConstant.new @name
          @name.analyse_types local_scope
          @entry = @name.entry
        end

        def add_as_ruby_method_to_scope(local_scope)
          @entry = local_scope.add_ruby_method(
            name: @name,
            c_name: @name,
            extern: true,
            scope: nil,
            arg_list: []
          )
        end

        def analyse_as_ruby_method(local_scope)
          @name = Rubex::AST::Expression::RubyMethodCall.new(
            Expression::Self.new, @name, []
          )
          @name.analyse_types local_scope
        end

        def assign_type_based_on_whether_wrapped_type
          if @entry.type.alias_type? || @entry.type.ruby_method? || @entry.type.c_function?
            @type = @entry.type.type
          else
            @type = @entry.type
          end
        end
      end # class Name
    end
  end
end
