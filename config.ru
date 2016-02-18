require './config/application.rb'
Celluloid.boot unless Celluloid.running?
MyApp.run
