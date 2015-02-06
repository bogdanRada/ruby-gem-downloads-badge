require './config/application.rb'
Lattice::Server.new("0.0.0.0", ENV['PORT'].present? ? ENV['PORT'] : 5000, root: Lattice.root).run
