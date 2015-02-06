require './config/application.rb'
Lattice::Server.new("127.0.0.1", ENV['PORT'].present? ? ENV['PORT'] : 5000, root: Lattice.root).run
