module Rubex
  module AST
    module Expression
      module Literal
        class HashLit < Base
          def initialize(key_val_pairs)
            @key_val_pairs = key_val_pairs
          end

          def analyse_types(local_scope)
            @has_temp = true
            @type = Rubex::DataType::RubyObject.new
            @key_val_pairs.map! do |k, v|
              k.analyse_for_target_type(@type, local_scope)
              v.analyse_for_target_type(@type, local_scope)
              [k.to_ruby_object, v.to_ruby_object]
            end
          end

          def generate_evaluation_code(code, local_scope)
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

          def allocate_temps(local_scope)
            @key_val_pairs.each do |k, v|
              k.allocate_temp local_scope, k.type
              v.allocate_temp local_scope, v.type
            end
          end

          def release_temps(local_scope)
            @key_val_pairs.each do |k, v|
              k.release_temp local_scope
              v.release_temp local_scope
            end
          end

          def generate_disposal_code(code)
            code << "#{@c_code} = 0;"
            code.nl
          end

          def c_code(_local_scope)
            @c_code
          end
        end
      end
    end
  end
end
