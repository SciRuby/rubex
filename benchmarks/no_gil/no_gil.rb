require 'no_gil.so'
require 'benchmark'

N = 9999999
Benchmark.bm do |x|
  x.report("with") do
    work_with_gil(N)
    work_with_gil(N)
    work_with_gil(N)
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
# with  2.780000   0.000000   2.780000 (  2.786049)
# without  3.180000   0.000000   3.180000 (  1.131401)
