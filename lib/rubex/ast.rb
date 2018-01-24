require 'rubex/ast/node'
require 'rubex/ast/statement'
Dir['./lib/rubex/ast/statement/**/*.rb'].sort.each { |f| require f }
require 'rubex/ast/expression'
Dir['./lib/rubex/ast/expression/**/*.rb'].sort.each { |f| require f }
require 'rubex/ast/top_statement'
