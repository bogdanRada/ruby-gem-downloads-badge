require 'celluloid_benchmark'

CelluloidBenchmark::Session.define do
  benchmark :production
  get 'https://github.com/bogdanRada/ruby-gem-downloads-badge/blob/master/README.md'

  benchmark :test
  get 'https://github.com/bogdanRada/ruby-gem-downloads-badge/blob/master/spec/test/README.md'

  benchmark :test2
  get 'https://github.com/bogdanRada/ruby-gem-downloads-badge/blob/master/spec/test/README2.md'

end
