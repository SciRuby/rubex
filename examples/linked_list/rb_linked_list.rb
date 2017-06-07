require 'linked_list.so'

list = LLNode.new(0)
10.times do |a|
  list.add_node(a)
end

list.print_list
