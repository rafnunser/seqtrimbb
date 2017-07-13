$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

RT_PATH=File.join(File.dirname(__FILE__))

$DB_PATH = File.join(RT_PATH, "DB")

if ENV['BBTOOLS_PATH']
   $BBPATH = ENV['BBTOOLS_PATH']
else
   $BBPATH = File.expand_path(File.dirname(%x[which bbmap.sh]))

end

OUTPUT_PATH = File.join(RT_PATH,'temp')

DEFAULT_FINAL_OUTPUT_PATH = OUTPUT_PATH

OUTPLUGINSTATS = OUTPUT_PATH

require 'seqtrimbb'

require 'minitest/autorun'

require 'plugin_manager.rb'

require 'params.rb'

require 'check_database.rb'

require 'check_external_database.rb'

require "logger"

$LOG = Logger.new(nil)
