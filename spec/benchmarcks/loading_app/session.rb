require 'celluloid_benchmark'

CelluloidBenchmark::Session.define do
  benchmark :production
  get 'http://ruby-gem-downloads-badge.herokuapp.com/rails'

  benchmark :test
  get 'http://ruby-gem-test.herokuapp.com/rails'

  benchmark :test2
  get 'http://ruby-gem-test2.herokuapp.com/rails'

  benchmark :local
  get 'http://localhost:5000/rails'
end
