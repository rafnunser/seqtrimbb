$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

RT_PATH=File.join(File.dirname(__FILE__))

$DB_PATH = File.join(RT_PATH, "DB")

OUTPUT_PATH = "/test/testoutput"

OUTPLUGINSTATS = OUTPUT_PATH

require 'seqtrimbb'

require 'minitest/autorun'

require 'plugin_manager.rb'

require 'params.rb'

require 'check_database.rb'

require "logger"

$LOG = Logger.new(nil)
