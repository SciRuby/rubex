require 'no_gil.so'
require 'benchmark'

N = 9999999
Benchmark.bm do |x|
  x.report("with") do
    n = Thread.new { work_with_gil(N) }
    m = Thread.new { work_with_gil(N) }
    o = Thread.new { work_with_gil(N) }
    n.join; m.join; o.join
  end

  x.report("without") do
    n = Thread.new { work_without_gil(N) }
    m = Thread.new { work_without_gil(N) }
    o = Thread.new { work_without_gil(N) }
    n.join; m.join; o.join
  end
end

# BENCHMARKS
#        user     system      total        real
# with  2.730000   0.000000   2.730000 (  2.731592)
# without  2.990000   0.000000   2.990000 (  1.076090)
