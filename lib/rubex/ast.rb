require 'rubex/ast/node'
require 'rubex/ast/statement'
require 'rubex/ast/expression'
Dir['./lib/rubex/ast/expression/**/*.rb'].sort.each { |f| require f }
require 'rubex/ast/top_statement'
