require 'benchmark'

N = 9999
Benchmark.bm do |x|
  x.report("no_gil") do
    n = Thread.new { work_without_gil(N) }
    n = Thread.new { work_without_gil(N) }
    n.join; n.join
  end

  x.report("gil") do
    work_with_gil(N)
    work_with_gil(N)
  end
end

