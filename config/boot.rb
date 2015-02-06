require 'pathname'

gemfile = ENV['BUNDLE_GEMFILE'] || File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(gemfile)

Lattice.root = Pathname.new(File.expand_path('../..', __FILE__))
$LOAD_PATH.unshift Lattice.root.join('app').to_s
