$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'test/unit'
require 'active_record'
require "#{File.dirname(__FILE__)}/../lib/event_attribute"

config_location = File.dirname(__FILE__) + '/database.yml'

config = YAML::load(IO.read(config_location))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3'])

load(File.dirname(__FILE__) + "/schema.rb")
