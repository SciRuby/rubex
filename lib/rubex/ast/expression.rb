module Rubex
  module AST
    module Expression
      class Base
        attr_accessor :typecast
        attr_reader :entry, :type, :has_temp, :result_code, :subexprs

        class << self
          def self.has_subexprs subexprs
            @subexprs = subexprs
          end
        end

        # In case an expr has to be of a certain type, like a string literal
        #   assigned to a char*, this method will analyse the literal in context
        #   to the target dtype.
        def analyse_for_target_type target_type, local_scope
          analyse_statement local_scope
        end

        # If the typecast exists, the typecast is made the overall type of
        # the expression.
        def analyse_statement local_scope
          if @typecast
            @typecast.analyse_statement(local_scope) 
            @type = @typecast.type
          end
        end

        def expression?; true; end

        def has_temp
          @has_temp
        end

        def c_code local_scope
          @typecast ? @typecast.c_code(local_scope) : ""
        end

        def possible_typecast code, local_scope
          @typecast ? @typecast.c_code(local_scope) : ""
        end

        def to_ruby_object
          ToRubyObject.new self
        end

        def from_ruby_object from_node
          FromRubyObject.new self, from_node
        end

        def release_temp local_scope
          local_scope.release_temp(@c_code) if @has_temp
        end

        def allocate_temp local_scope, type
          if @has_temp
            @c_code = local_scope.allocate_temp(type)
          end
        end

        def allocate_temps local_scope
          if @subexprs
            @subexprs.each { |expr| expr.allocate_temp(local_scope, expr.type) }
          end
        end

        def release_temps local_scope
          if @subexprs
            @subexprs.each { |expr| expr.release_temp(local_scope) }
          end
        end

        def generate_evaluation_code code, local_scope
          
        end

        def generate_disposal_code code

        end

        def generate_assignment_code rhs, code, local_scope
          
        end
      end

      class Typecast < Base
        attr_reader :type

        def initialize dtype, ptr_level
          @dtype, @ptr_level = dtype, ptr_level
        end

        def analyse_statement local_scope
          @type = Rubex::Helpers.determine_dtype @dtype, @ptr_level
        end

        def c_code local_scope
          "(#{@type.to_s})"
        end
      end # class Typecast

      class SizeOf < Base
        attr_reader :type

        def initialize type, ptr_level
          @size_of_type = Helpers.determine_dtype type, ptr_level
        end

        def analyse_statement local_scope
          @type = DataType::ULInt.new
          super
        end

        def c_code local_scope
          "sizeof(#{@size_of_type})"
        end
      end # class SizeOf

      class Binary < Base
        include Rubex::Helpers::NodeTypeMethods

        attr_reader :operator
        attr_accessor :left, :right
        # Final return type of expression
        attr_accessor :type, :subexprs

        def initialize left, operator, right
          @left, @operator, @right = left, operator, right
          @@analyse_visited = []
          @subexprs = []
        end

        def analyse_statement local_scope
          analyse_left_and_right_nodes local_scope, self
          analyse_return_type local_scope, self
          super
        end

        def allocate_temps local_scope
          @subexprs.each do |expr|
            if expr.is_a?(Binary)
              expr.allocate_temps local_scope
            else
              expr.allocate_temp local_scope, expr.type
            end
          end
        end

        def generate_evaluation_code code, local_scope
          @left.generate_evaluation_code code, local_scope
          @right.generate_evaluation_code code, local_scope
        end

        def generate_disposal_code code
          @left.generate_disposal_code code
          @right.generate_disposal_code code
        end

        def c_code local_scope
          code = super
          code << "( "
          left_code = @left.c_code(local_scope)
          right_code = @right.c_code(local_scope)
          if type_of(@left).object? || type_of(@right).object?
            left_ruby_code = @left.type.to_ruby_object(left_code)
            right_ruby_code = @right.type.to_ruby_object(right_code)

            if ["&&", "||"].include?(@operator)
              code << Rubex::C_MACRO_INT2BOOL + 
                "(RTEST(#{left_ruby_code}) #{@operator} RTEST(#{right_ruby_code}))"
            else
              code << "rb_funcall(#{left_ruby_code}, rb_intern(\"#{@operator}\") "
              code << ", 1, #{right_ruby_code})"
            end
          else
            code << "#{left_code} #{@operator} #{right_code}"
          end
          code << " )"

          code
        end

        def == other
          self.class == other.class && @type  == other.type &&
          @left == other.left  && @right == other.right &&
          @operator == other.operator
        end

      private

        def type_of expr
          t = expr.type
          return (t.c_function? ? t.type : t)
        end

        def analyse_left_and_right_nodes local_scope, tree
          if tree.respond_to?(:left)
            analyse_left_and_right_nodes local_scope, tree.left

            if !@@analyse_visited.include?(tree.left.object_id)
              if tree.right.type
                tree.left.analyse_for_target_type(tree.right.type, local_scope)
              else
                tree.left.analyse_statement(local_scope)
              end
              @subexprs << tree.left
              @@analyse_visited << tree.left.object_id
            end
            
            if !@@analyse_visited.include?(tree.right.object_id)
              if tree.left.type
                tree.right.analyse_for_target_type(tree.left.type, local_scope)
              else
                tree.right.analyse_statement(local_scope)
              end
              @subexprs << tree.right
              @@analyse_visited << tree.right.object_id
            end

            @@analyse_visited << tree.object_id

            analyse_left_and_right_nodes local_scope, tree.right
          end
        end

        def analyse_return_type local_scope, tree
          if tree.respond_to? :left
            analyse_return_type local_scope, tree.left
            analyse_return_type local_scope, tree.right

            if ['==', '<', '>', '<=', '>=', '||', '&&', '!='].include? tree.operator
              if type_of(tree.left).object? || type_of(tree.right).object?
                tree.type = Rubex::DataType::Boolean.new
              else
                tree.type = Rubex::DataType::CBoolean.new
              end
            else
              if tree.left.type.bool? || tree.right.type.bool?
                raise Rubex::TypeMismatchError, "Operation #{tree.operator} cannot"\
                  "be performed between #{tree.left} and #{tree.right}"
              end
              tree.type = Rubex::Helpers.result_type_for(
                     type_of(tree.left), type_of(tree.right))
            end
          end
        end
      end # class Binary

      class UnaryBase < Base
        def initialize expr
          @expr = expr
        end

        def analyse_statement local_scope
          @expr.analyse_statement local_scope
          @type = @expr.type
          @expr.allocate_temps local_scope
          @expr.allocate_temp local_scope, @type
          @expr.release_temps local_scope
          @expr.release_temp local_scope
          @expr = @expr.to_ruby_object if @type.object?
        end

        def generate_evaluation_code code, local_scope
          @expr.generate_evaluation_code code, local_scope         
        end
      end

      class UnaryNot < UnaryBase
        attr_reader :type

        def c_code local_scope
          code = @expr.c_code(local_scope)
          if @type.object?
            "rb_funcall(#{code}, rb_intern(\"!\"), 0)"
          else
            "!#{code}"
          end
        end
      end

      class UnarySub < UnaryBase
        attr_reader :type

        def c_code local_scope
          code = @expr.c_code(local_scope)
          if @type.object?
            "rb_funcall(#{code}, rb_intern(\"-\"), 0)"
          else
            "-#{code}"
          end
        end
      end

      class Ampersand < UnaryBase
        attr_reader :type

        def analyse_statement local_scope
          @expr.analyse_statement local_scope
          @type = DataType::CPtr.new @expr.type
        end

        def c_code local_scope
          "&#{@expr.c_code(local_scope)}"
        end
      end

      class UnaryBitNot < UnaryBase
        attr_reader :type

        def c_code local_scope
          code = @expr.c_code(local_scope)
          if @type.object?
            "rb_funcall(#{code}, rb_intern(\"~\"), 0)"
          else
            "~#{code}"
          end
        end
      end

      class Unary < Base
        attr_reader :operator, :expr, :type

        OP_CLASS_MAP = {
          '&' => Ampersand,
          '-' => UnarySub,
          '!' => UnaryNot,
          '~' => UnaryBitNot
        }

        def initialize operator, expr
          @operator, @expr = operator, expr
        end

        def analyse_statement local_scope
          @expr = OP_CLASS_MAP[@operator].new(@expr)
          @expr.analyse_statement local_scope
          @type = @expr.type
          super
        end

        def generate_evaluation_code code, local_scope
          @expr.generate_evaluation_code code, local_scope
        end

        def c_code local_scope
          code = super
          code << @expr.c_code(local_scope)
        end
      end # class Unary

      class ElementRef < Base
        # FIXME: get rid of this object_ptr for good.
        attr_reader :entry, :pos, :type, :name, :object_ptr, :subexprs
        extend Forwardable
        def_delegators :@element_ref, :generate_disposal_code, :generate_evaluation_code,
                       :analyse_statement, :generate_element_ref_code,
                       :generate_assignment_code, :has_temp, :c_code, :allocate_temp,
                       :allocate_temps, :release_temp, :release_temps, :to_ruby_object,
                       :from_ruby_object

        def initialize name, pos
          @name, @pos = name, pos
          @subexprs = []
        end

        def analyse_statement local_scope, struct_scope=nil
          @entry = struct_scope.nil? ? local_scope.find(@name) : struct_scope[@name]
          @type = @entry.type.object? ? @entry.type : @entry.type.type
          @element_ref = proper_analysed_type
          @element_ref.analyse_statement local_scope
          super(local_scope)
        end

        private

        def proper_analysed_type
          if ruby_object_c_array?
            @object_ptr = true
            CVarElementRef.new(self)
          else
            if ruby_array?
              RubyArrayElementRef.new(self)
            elsif ruby_hash?
              RubyHashElementRef.new(self)
            elsif generic_ruby_object?
              RubyObjectElementRef.new(self)
            else
              CVarElementRef.new(self)
            end
          end          
        end

        def ruby_array?
          @type.ruby_array?
        end

        def ruby_hash?
          @type.ruby_hash?
        end

        def generic_ruby_object?
          @type.object?
        end

        def ruby_object_c_array?
          @entry.type.cptr? && @entry.type.type.object?
        end        
      end # class ElementRef

      class AnalysedElementRef < Base
        attr_reader :entry, :pos, :type, :name, :object_ptr, :subexprs
        def initialize element_ref
          @element_ref = element_ref
          @pos = @element_ref.pos
          @entry = @element_ref.entry
          @name = @element_ref.name
          @subexprs = @element_ref.subexprs
          @object_ptr = @element_ref.object_ptr
          @type = @element_ref.type
        end

        def analyse_statement local_scope
          @pos.analyse_statement local_scope
        end

        def c_code local_scope
          code = super
          code << @c_code
          code
        end
      end

      class RubyObjectElementRef < AnalysedElementRef
        def analyse_statement local_scope
          super
          @has_temp = true
          @pos = @pos.to_ruby_object
          @subexprs << @pos
        end

        def generate_evaluation_code code, local_scope
          @pos.generate_evaluation_code code, local_scope
          code << "#{@c_code} = rb_funcall(#{@entry.c_name}, rb_intern(\"[]\"), 1, "
          code << "#{@pos.c_code(local_scope)});"
          code.nl
          @pos.generate_disposal_code code
        end

        def generate_disposal_code code
          code << "#{@c_code} = 0;"
          code.nl  
        end

        def generate_element_ref_code expr, code, local_scope
          @pos.generate_evaluation_code code, local_scope
          str = "#{@c_code} = rb_funcall(#{expr.c_code(local_scope)}."
          str << "#{@entry.c_name}, rb_intern(\"[]\"), 1, "
          str << "#{@pos.c_code(local_scope)});"
          code << str
          code.nl
          @pos.generate_disposal_code code
        end

        def generate_assignment_code rhs, code, local_scope
          @pos.generate_evaluation_code code, local_scope
          code << "rb_funcall(#{@entry.c_name}, rb_intern(\"[]=\"), 2,"
          code << "#{@pos.c_code(local_scope)}, #{rhs.c_code(local_scope)});"
          code.nl
          @pos.generate_disposal_code code
        end
      end

      class RubyArrayElementRef < RubyObjectElementRef
        def generate_evaluation_code code, local_scope
          @pos.generate_evaluation_code code, local_scope
          code << "#{@c_code} = RARRAY_AREF(#{@entry.c_name}, #{@pos.c_code(local_scope)});"
          code.nl
          @pos.generate_disposal_code code
        end
      end # class RubyArrayElementRef

      class RubyHashElementRef < RubyObjectElementRef
        def generate_evaluation_code code, local_scope
          @pos.generate_evaluation_code code, local_scope
          code << "#{@c_code} = rb_hash_aref(#{@entry.c_name}, #{@pos.c_code(local_scope)});"
          @pos.generate_disposal_code code
        end

        def generate_assignment_code rhs, code, local_scope
          @pos.generate_evaluation_code code, local_scope
          code << "rb_hash_aset(#{@entry.c_name}, #{@pos.c_code(local_scope)},"
          code << "#{rhs.c_code(local_scope)});"
          @pos.generate_disposal_code code
        end
      end # class RubyHashElementRef

      class CVarElementRef < AnalysedElementRef
        def analyse_statement local_scope
          @pos.analyse_statement local_scope
        end

        def generate_evaluation_code code, local_scope
          @pos.generate_evaluation_code code, local_scope
          @c_code = "#{@entry.c_name}[#{@pos.c_code(local_scope)}]"
        end

        def generate_element_ref_code expr, code, local_scope
          generate_evaluation_code code, local_scope
        end

        def generate_assignment_code rhs, code, local_scope
          @pos.generate_evaluation_code code, local_scope
          code << "#{@entry.c_name}[#{@pos.c_code(local_scope)}] = "
          code << "#{rhs.c_code(local_scope)};"
          @pos.generate_disposal_code code
        end
      end # class CVarElementRef

      class Self < Base
        def c_code local_scope
          local_scope.self_name
        end

        def type
          Rubex::DataType::RubyObject.new
        end
      end # class Self

      class RubyConstant < Base
        include Rubex::AST::Expression
        attr_reader :name, :entry, :type

        def initialize name
          @name = name
        end

        def analyse_statement local_scope
          @type = Rubex::DataType::RubyConstant.new @name
          c_name = Rubex::DEFAULT_CLASS_MAPPINGS[@name]
          @entry = Rubex::SymbolTable::Entry.new name, c_name, @type, nil
        end

        def c_code local_scope
          if @entry.c_name # built-in constant.
            @entry.c_name
          else
            "rb_const_get(CLASS_OF(#{local_scope.self_name}), rb_intern(\"#{@entry.name}\"))"
          end
        end
      end # class RubyConstant

      # Singular name node with no sub expressions.
      class Name < Base
        def initialize name
          @name = name
        end

        # Used when the node is a LHS of an assign statement.
        def analyse_declaration rhs, local_scope
          @entry = local_scope.find @name
          unless @entry
            local_scope.add_ruby_obj(name: @name,
              c_name: Rubex::VAR_PREFIX + @name, value: @rhs)
            @entry = local_scope[@name]
          end
          @type = @entry.type
        end

        def analyse_for_target_type target_type, local_scope
          @entry = local_scope.find @name
          
          if @entry && @entry.type.c_function? && target_type.c_function_ptr?
            @type = @entry.type
          else
            analyse_statement local_scope
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
        def analyse_statement local_scope
          @entry = local_scope.find @name
          if !@entry
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

        def generate_evaluation_code code, local_scope
          if @name.respond_to? :generate_evaluation_code
            @name.generate_evaluation_code code, local_scope
          end
        end

        def generate_disposal_code code
          if @name.respond_to? :generate_disposal_code
            @name.generate_disposal_code code
          end
        end

        def generate_assignment_code rhs, code, local_scope
          code << "#{self.c_code(local_scope)} = #{rhs.c_code(local_scope)};"
          code.nl
          rhs.generate_disposal_code code
        end

        def c_code local_scope
          code = super
          if @name.is_a?(Rubex::AST::Expression::Base)
            code << @name.c_code(local_scope)
          else
            code << @entry.c_name
          end

          code
        end
        
        private

        def ruby_constant?
          @name[0].match /[A-Z]/
        end

        def analyse_as_ruby_constant local_scope
          @name = Expression::RubyConstant.new @name
          @name.analyse_statement local_scope
          @entry = @name.entry          
        end

        def add_as_ruby_method_to_scope local_scope
          @entry = local_scope.add_ruby_method(
            name: @name,
            c_name: @name,
            extern: true,
            scope: nil,
            arg_list: [])
        end

        def analyse_as_ruby_method local_scope
          @name = Rubex::AST::Expression::RubyMethodCall.new(
            Expression::Self.new, @name, [])
          @name.analyse_statement local_scope
        end

        def assign_type_based_on_whether_wrapped_type
          if @entry.type.alias_type? || @entry.type.ruby_method? || @entry.type.c_function?
            @type = @entry.type.type
          else
            @type = @entry.type
          end
        end
      end # class Name

      class MethodCall < Base
        attr_reader :method_name, :type

        def initialize invoker, method_name, arg_list
          @method_name, @invoker, @arg_list = method_name, invoker, arg_list
        end

        # local_scope - is the local method scope.
        def analyse_statement local_scope
          @entry = local_scope.find(@method_name)
          if method_not_within_scope? local_scope
            raise Rubex::NoMethodError, "Cannot call #{@name} from this method."
          end
          super
        end

        def generate_evaluation_code code, local_scope
        end

        def generate_disposal_code code
        end

      private

        def type_check_arg_types entry
          @arg_list.map!.with_index do |arg, idx|
            Helpers.to_lhs_type(entry.type.base_type.arg_list[idx], arg)
          end
        end

        # Checks if method being called is of the same type of the caller. For
        # example, only instance methods can call instance methods and only 
        # class methods can call class methods. C functions are accessible from
        # both instance methods and class methods.
        #
        # Since there is no way to determine whether methods outside the scope
        # of the compiled Rubex file are singletons or not, Rubex will assume
        # that they belong to the correct scope and will compile a call to those
        # methods anyway. Error, if any, will be caught only at runtime.
        def method_not_within_scope? local_scope
          caller_entry = local_scope.find local_scope.name
          if ( caller_entry.singleton? &&  @entry.singleton?) || 
             (!caller_entry.singleton? && !@entry.singleton?) ||
             @entry.c_function?
            false
          else
            true
          end
        end
      end # class MethodCall

      class RubyMethodCall < MethodCall
        def analyse_statement local_scope
          super
          @type = Rubex::DataType::RubyObject.new
          prepare_arg_list(local_scope) if !@entry.extern? && @arg_list.size > 0
        end

        def c_code local_scope
          code = super
          code << code_for_ruby_method_call(local_scope)
          code
        end

        private

        def prepare_arg_list local_scope
          @arg_list_var = @entry.c_name + Rubex::ACTUAL_ARGS_SUFFIX
          args_size = @entry.type.arg_list&.size || 0
          local_scope.add_carray(name: @arg_list_var, c_name: @arg_list_var,
                                 dimension: Literal::Int.new("#{args_size}"), 
                                 type: @type)
        end

        def code_for_ruby_method_call local_scope
          str = ""
          if @entry.extern?
            str << "rb_funcall(#{@invoker.c_code(local_scope)}, "
            str << "rb_intern(\"#{@method_name}\"), "
            str << "#{@arg_list.size}"
            @arg_list.each do |arg|
              str << " ,#{arg.type.to_ruby_object(arg.c_code(local_scope))}"
            end
            str << ", NULL" if @arg_list.empty?
            str << ")"
          else
            str << populate_method_args_into_value_array(local_scope)
            str << actual_ruby_method_call(local_scope)
          end
          str
        end

        def actual_ruby_method_call local_scope
          str = "#{@entry.c_name}(#{@arg_list.size}, #{@arg_list_var || "NULL"},"
          str << "#{local_scope.self_name})"
        end

        def populate_method_args_into_value_array local_scope
          str = ""
          @arg_list.each_with_index do |arg, idx|
            str = "#{@arg_list_var}[#{idx}] = "
            str << "#{arg.type.to_ruby_object(arg.c_code(local_scope))}"
            str << ";\n"
          end

          str
        end
      end # class RubyMethodCall

      class CFunctionCall < MethodCall
        def analyse_statement local_scope
          super
          @type = @entry.type.base_type
          append_self_argument if !@entry.extern?
          type_check_arg_types @entry          
        end

        def c_code local_scope
          code = super
          code << code_for_c_method_call(local_scope)
          code
        end

        private

        def append_self_argument
          @arg_list << Expression::Self.new
        end

        def code_for_c_method_call local_scope
          str = "#{@entry.c_name}("
          str << @arg_list.map { |a| a.c_code(local_scope) }.join(",")
          str << ")"
          str
        end
      end # class CFunctionCall

      class CommandCall < Base
        attr_reader :expr, :command, :arg_list, :type, :entry

        def initialize expr, command, arg_list
          @expr, @command, @arg_list = expr, command, arg_list
          @subexprs = []
        end

        def analyse_statement local_scope
          analyse_arg_list_and_add_to_subexprs local_scope
          @entry = local_scope.find(@command)
          if @expr.nil? # Case for implicit 'self' when a method in the class itself is being called.
            @expr = Expression::Self.new if @entry && !@entry.extern
          else
            @expr.analyse_statement(local_scope)
            @expr.allocate_temps local_scope
            @expr.allocate_temp local_scope, @expr.type
          end
          add_as_ruby_method_to_symtab(local_scope) if !@entry          
          analyse_command_type local_scope
          super
        end

        def generate_evaluation_code code, local_scope
          @c_code = ""
          @arg_list.each do |arg|
            arg.generate_evaluation_code code, local_scope
          end
          @expr.generate_evaluation_code(code, local_scope) if @expr
          @command.generate_evaluation_code code, local_scope
          @c_code << @command.c_code(local_scope)
        end

        def generate_disposal_code code
          @expr.generate_disposal_code(code) if @expr
          @arg_list.each do |arg|
            arg.generate_disposal_code code
          end
        end

        def generate_assignment_code rhs, code, local_scope
          generate_evaluation_code code, local_scope
          code << "#{self.c_code(local_scope)} = #{rhs.c_code(local_scope)};"
          code.nl
        end

        def c_code local_scope
          code = super
          code << @c_code
          code
        end

        private

        def analyse_arg_list_and_add_to_subexprs local_scope
          @arg_list.each do |arg|
            arg.analyse_statement local_scope
            @subexprs << arg
          end
        end

        def add_as_ruby_method_to_symtab local_scope
          @entry = local_scope.add_ruby_method(
            name: @command, 
            c_name: @command, 
            extern: true,
            arg_list: @arg_list,
            scope: nil)
        end

        def struct_member_call?
          @expr && ((@expr.type.cptr? && @expr.type.type.struct_or_union?) || 
                    (@expr.type.struct_or_union?))
        end

        def ruby_method_call?
          @entry.type.ruby_method?
        end

        def c_function_call?
          @entry.type.base_type.c_function?
        end

        def allocate_and_release_temps local_scope
          @command.allocate_temps local_scope
          @command.allocate_temp local_scope, @type
          @command.release_temps local_scope
          @command.release_temp local_scope
        end

        def analyse_command_type local_scope
          if struct_member_call?
            @command = Expression::StructOrUnionMemberCall.new @expr, @command, @arg_list
          elsif ruby_method_call?
            @command = Expression::RubyMethodCall.new @expr, @command, @arg_list
          elsif c_function_call?
            @command = Expression::CFunctionCall.new @expr, @command,  @arg_list
          end
          @command.analyse_statement local_scope
          @type = @command.type
          allocate_and_release_temps local_scope
        end
      end # class CommandCall

      class StructOrUnionMemberCall < CommandCall
        def analyse_statement local_scope
          scope = @expr.type.base_type.scope

          if @command.is_a? String
            if !scope.has_entry?(@command)
              raise "Entry #{@command.name} does not exist in #{@expr}."
            end
            @command = Expression::Name.new @command            
            @command.analyse_statement scope
          elsif @command.is_a? Rubex::AST::Expression::ElementRef
            @command = Expression::ElementRefMemberCall.new @expr, @command, @arg_list
            @command.analyse_statement local_scope, scope
          end
          @has_temp = @command.has_temp
          @type = @command.type
        end

        def c_code local_scope
           if @command.has_temp
             @command.c_code(local_scope)
           else
            op = @expr.type.cptr? ? "->" : "."
            "#{@expr.c_code(local_scope)}#{op}#{@command.c_code(local_scope)}"
          end
        end
      end # StructOrUnionMemberCall

      class ElementRefMemberCall < StructOrUnionMemberCall
        def analyse_statement local_scope, struct_scope
          @command.analyse_statement local_scope, struct_scope
          @type = @command.type
          @has_temp = @command.has_temp
          allocate_and_release_temps local_scope
        end

        def generate_evaluation_code code, local_scope
          @command.generate_element_ref_code @expr, code, local_scope          
        end

        def c_code local_scope
          @command.c_code(local_scope)
        end
      end # class ElementRefMemberCall

      class ArgDeclaration < Base
        attr_reader :entry, :type, :data_hash

        def initialize data_hash
          @data_hash = data_hash
        end

        # FIXME: Support array of function pointers and array in arguments.
        def analyse_statement local_scope, extern: false
          var, dtype, ident, ptr_level, value = fetch_data
          name, c_name = ident, Rubex::ARG_PREFIX + ident 
          @type = Helpers.determine_dtype(dtype, ptr_level)
          value.analyse_statement(local_scope) if value
          add_arg_to_symbol_table name, c_name, @type, value, extern, local_scope
        end # def analyse_statement
        
        private

        def add_arg_to_symbol_table name, c_name, type, value, extern, local_scope
          if !extern
            @entry = local_scope.add_arg(name: name, c_name: c_name, type: @type, value: value)
          end
        end
        
        def fetch_data
          var       = @data_hash[:variables][0]
          dtype     = @data_hash[:dtype]
          ident     = var[:ident]
          ptr_level = var[:ptr_level]
          value     = var[:value]

          [var, dtype, ident, ptr_level, value]
        end
      end # class ArgDeclaration

      # Function argument is a function pointer.
      class FuncPtrArgDeclaration < ArgDeclaration
        def initialize data_hash
          super
        end
        
        def analyse_statement local_scope, extern: false
          var, dtype, ident, ptr_level, value = fetch_data
          cfunc_return_type = Helpers.determine_dtype(dtype, ident[:return_ptr_level])
          arg_list = ident[:arg_list].analyse_statement(local_scope)
          ptr_level = "*" if ptr_level.empty?
          name, c_name = ident[:name], Rubex::ARG_PREFIX + ident[:name]
          @type = Helpers.determine_dtype(
            DataType::CFunction.new(name, c_name, arg_list, cfunc_return_type, nil), ptr_level)
          add_arg_to_symbol_table name, c_name, @type, value, extern, local_scope
        end
      end # class FuncPtrArgDeclaration

      # Function argument is the argument of a function pointer.
      class FuncPtrInternalArgDeclaration < ArgDeclaration
        def analyse_statement local_scope, extern: false
          var, dtype, ident, ptr_level, value = fetch_data
          @type = Helpers.determine_dtype(dtype, ptr_level)
        end
      end # class FuncPtrInternalArgDeclaration

      class CoerceObject < Base
        attr_reader :expr

        extend Forwardable

        def_delegators :@expr, :generate_evaluation_code, :generate_disposal_code,
          :generate_assignment_code, :allocate_temp, :allocate_temps,
          :release_temp, :release_temps, :type
      end

      # Internal class to typecast from a C type to another C type.
      class TypecastTo < CoerceObject
        def initialize dtype
          
        end
        # TODO
      end

      # internal node for converting to ruby object.
      class ToRubyObject < CoerceObject
        attr_reader :type

        def initialize expr
          @expr = expr
          @type = Rubex::DataType::RubyObject.new
        end

        def c_code local_scope
          t = @expr.type
          t = (t.c_function? || t.alias_type?) ? t.type : t
          "#{t.to_ruby_object(@expr.c_code(local_scope))}"
        end
      end

      # internal node for converting from ruby object.
      class FromRubyObject < CoerceObject
        # expr - Expression to convert
        # from_node - LHS expression. Of type Rubex::AST::Expression
        def initialize expr, from_node
          @expr = expr
          @type = @expr.type
          @from_node = from_node
        end

        def c_code local_scope
          "#{@from_node.type.from_ruby_object(@expr.c_code(local_scope))}"
        end
      end

      class BlockGiven < Base
        attr_reader :type

        def analyse_statement local_scope
          @type = DataType::CBoolean.new
        end

        def c_code local_scope
          "rb_block_given_p()"
        end
      end

      # Internal node that denotes empty expression for a statement for example
      #   the `return` for a C function with return type `void`.
      class Empty < Base
        attr_reader :type

        def analyse_statement local_scope
          @type = DataType::Void.new
        end
      end

      module Literal
        class Base < Rubex::AST::Expression::Base
          attr_reader :name, :type

          def initialize name
            @name = name
          end

          def c_code local_scope
            code = super
            code << @name
          end

          def c_name
            @name
          end

          def literal?; true; end

          def == other
            self.class == other.class && @name == other.name
          end
        end # class Base

        class ArrayLit < Literal::Base
          include Enumerable

          attr_accessor :c_array

          def each &block
            @array_list.each(&block)
          end

          def initialize array_list
            @array_list = array_list
            @subexprs = []
          end

          def analyse_statement local_scope
            @has_temp = true
            @type = DataType::RubyObject.new
            @array_list.map! do |e|    
              e.analyse_statement local_scope
              e = e.to_ruby_object
              @subexprs << e
              e
            end
          end

          def generate_evaluation_code code, local_scope
            code << "#{@c_code} = rb_ary_new2(#{@array_list.size});"
            code.nl
            @array_list.each do |e|
              code << "rb_ary_push(#{@c_code}, #{e.c_code(local_scope)});"
              code.nl
            end
          end

          def generate_disposal_code code
            code << "#{@c_code} = 0;"
            code.nl
          end

          def c_code local_scope
            @c_code
          end
        end # class ArrayLit

        class HashLit < Literal::Base
          def initialize key_val_pairs
            @key_val_pairs = key_val_pairs
          end

          def analyse_statement local_scope
            @has_temp = true
            @type = Rubex::DataType::RubyObject.new
            @key_val_pairs.map! do |k, v|
              k.analyse_for_target_type(@type, local_scope)
              v.analyse_for_target_type(@type, local_scope)
              [k.to_ruby_object, v.to_ruby_object]
            end
          end

          def generate_evaluation_code code, local_scope
            code << "#{@c_code} = rb_hash_new();"
            code.nl
            @key_val_pairs.each do |k, v|
              k.generate_evaluation_code(code, local_scope)
              v.generate_evaluation_code(code, local_scope)

              code << "rb_hash_aset(#{@c_code}, #{k.c_code(local_scope)}, "
              code << "#{v.c_code(local_scope)});"
              code.nl

              k.generate_disposal_code code
              v.generate_disposal_code code
              code.nl
            end            
          end

          def allocate_temps local_scope
            @key_val_pairs.each do |k,v|
              k.allocate_temp local_scope, k.type
              v.allocate_temp local_scope, v.type
            end
          end

          def release_temps local_scope
            @key_val_pairs.each do |k,v|
              k.release_temp local_scope
              v.release_temp local_scope
            end
          end

          def generate_disposal_code code
            code << "#{@c_code} = 0;"
            code.nl
          end

          def c_code local_scope
            @c_code
          end
        end

        class RubySymbol < Literal::Base
          def initialize name
            super(name[1..-1])
            @type = Rubex::DataType::RubySymbol.new
          end

          def generate_evaluation_code code, local_scope
            @c_code = "ID2SYM(rb_intern(\"#{@name}\"))"
          end

          def c_code local_scope
            @c_code
          end
        end

        class Double < Literal::Base
          def initialize name
            super
            @type = Rubex::DataType::F64.new
          end
        end

        class Int < Literal::Base
          def initialize name
            super
            @type = Rubex::DataType::Int.new
          end
        end

        class StringLit < Literal::Base
          def initialize name
            super           
          end

          def analyse_for_target_type target_type, local_scope
            if target_type.char_ptr?
              @type = Rubex::DataType::CStr.new
            elsif target_type.object?
              @type = Rubex::DataType::RubyString.new
              analyse_statement local_scope
            else
              raise Rubex::TypeError, "Cannot assign #{target_type} to string."
            end
          end

          def analyse_statement local_scope
            @type = Rubex::DataType::RubyString.new unless @type
            @has_temp = 1
          end

          def generate_evaluation_code code, local_scope
            if @type.cstr?
              @c_code = "\"#{@name}\""
            else
              code << "#{@c_code} = rb_str_new2(\"#{@name}\");"
              code.nl
            end
          end

          def generate_disposal_code code
            if @type.object?
              code << "#{@c_code} = 0;"
              code.nl
            end
          end

          def c_code local_scope
            @c_code
          end
        end # class StringLit

        class Char < Literal::Base
          def initialize name
            super
          end

          def analyse_for_target_type target_type, local_scope
            if target_type.char?
              @type = Rubex::DataType::Char.new
            elsif target_type.object?
              @type = Rubex::DataType::RubyString.new
              analyse_statement local_scope
            else
              raise Rubex::TypeError, "Cannot assign #{target_type} to string."
            end
          end

          def analyse_statement local_scope
            @type = Rubex::DataType::RubyString.new unless @type
          end

          def generate_evaluation_code code, local_scope
            if @type.char?
              @c_code = @name
            else
              @c_code = "rb_str_new2(\"#{@name[1]}\")"
            end
          end

          def c_code local_scope
            @c_code
          end
        end # class Char

        class True < Literal::Base
          def initialize name
            super
          end

          def analyse_for_target_type target_type, local_scope
            if target_type.object?
              @type = Rubex::DataType::TrueType.new
            else
              @type = Rubex::DataType::CBoolean.new
            end
          end

          def analyse_statement local_scope
            @type = Rubex::DataType::TrueType.new
          end

          def c_code local_scope
            if @type.object?
              @name
            else
              "1"
            end
          end
        end # class True

        class False < Literal::Base
          def initialize name
            super
          end

          def analyse_for_target_type target_type, local_scope
            if target_type.object?
              @type = Rubex::DataType::FalseType.new
            else
              @type = Rubex::DataType::CBoolean.new
            end
          end

          def analyse_statement local_scope
            @type = Rubex::DataType::FalseType.new
          end

          def c_code local_scope
            if @type.object?
              @name
            else
              "0"
            end
          end
        end # class False

        class Nil < Literal::Base
          def initialize name
            super
            @type = Rubex::DataType::NilType.new
          end
        end # class Nil

        class CNull < Literal::Base
          def initialize name
            # Rubex treats NULL's dtype as void*
            super
            @type = Rubex::DataType::CPtr.new(Rubex::DataType::Void.new)
          end
        end # class CNull
      end # module Literal
    end # module Expression
  end # module AST
end # module Rubex
