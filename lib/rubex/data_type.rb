require_relative 'data_type_helpers/helpers'
Dir['./lib/rubex/data_type_helpers/**/*.rb'].sort.each { |f| require f }
Dir['./lib/rubex/data_type/**/*.rb'].sort.each { |f| require f }

# TODO: How to store this in a Ruby class? Use BigDecimal?
# class LF64
#   def to_s; "long double"; end

#   def to_ruby_object(arg); "INT2NUM"; end

#   def from_ruby_object(arg); "(int32_t)NUM2INT"; end
# end
