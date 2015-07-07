# Running `rake console` from the command line will execute this task.
# It will start a new pry console and import the Ibex module to start debugging.
task :console do
    require 'pry'
    require_relative 'lib/ibex'
    include Ibex

    ARGV.clear
    Pry::CLI.parse_options
end
