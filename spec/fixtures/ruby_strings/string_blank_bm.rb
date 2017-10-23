# coding: utf-8

# This file contains a benchmark between Rubex's blank? and the String#blank?
#   from the the fast_blank gem.

require_relative "ruby_strings.#{os_extension}"
require 'fast_blank'
require 'benchmark'
require 'benchmark/ips'

str = ' ' * 2500 + 'dff'

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.time = 5
  x.warmup = 2

  x.report('fast_blank') do
    str.blank?
  end

  x.report('blank?') do
    blank? str
  end

  x.compare!
end

# Warming up --------------------------------------
#           fast_blank     3.401k i/100ms
#               blank?    57.041k i/100ms
# Calculating -------------------------------------
#           fast_blank     35.068k (± 0.4%) i/s -    176.852k in   5.043263s
#               blank?    671.289k (± 1.1%) i/s -      3.365M in   5.014016s
#
# Comparison:
#               blank?:   671289.0 i/s
#           fast_blank:    35067.6 i/s - 19.14x  slower
