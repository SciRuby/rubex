# This file contains a benchmark between Rubex's blank? and the String#blank?
#   from the the fast_blank gem.

require_relative 'ruby_strings.so'
require 'fast_blank'
require 'benchmark'
require 'benchmark/ips'

str= "     "*50 + "dff"

Benchmark.bm do |x|
  x.report("fast_blank") do
    str.blank?
  end

  x.report("blank?") do
    blank? str
  end
end

Benchmark.ips do |x|
  x.report("fast_blank") do
    str.blank?
  end

  x.report("blank?") do
    blank? str
  end

  x.compare!
end

# Results
#        user     system      total        real
# fast_blank  0.000000   0.000000   0.000000 (  0.000012)
# blank?  0.000000   0.000000   0.000000 (  0.000005)
# Warming up --------------------------------------
#           fast_blank    14.890k i/100ms
#               blank?   103.550k i/100ms
# Calculating -------------------------------------
#           fast_blank    165.912k (± 3.6%) i/s -    833.840k in   5.032727s
#               blank?      2.390M (± 2.3%) i/s -     12.012M in   5.028894s
# 
# Comparison:
#               blank?:  2390066.7 i/s
#           fast_blank:   165912.1 i/s - 14.41x  slower
# 