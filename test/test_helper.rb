$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
###############################################################################
# FINDS
###############################################################################

SEQTRIM_PATH = File.join(File.dirname(__FILE__),'..')

# Finds classes in 'lib' folder
$: << File.expand_path(File.join(SEQTRIM_PATH,'lib'))
# Finds classes in 'seqtrimbb' folder
$: << File.expand_path(File.join(SEQTRIM_PATH,'lib','seqtrimbb'))
# Finds classes in 'classes' folder
$: << File.expand_path(File.join(SEQTRIM_PATH,'lib','seqtrimbb','classes'))
# Finds classes in 'classes/databases_support' folder
$: << File.expand_path(File.join(SEQTRIM_PATH,'lib','seqtrimbb','classes','databases_support'))
# Finds classes in 'plugins' folder
$: << File.expand_path(File.join(SEQTRIM_PATH,'lib','seqtrimbb','plugins'))

ROOT_PATH=File.join(File.dirname(__FILE__))

DB_PATH = File.join(ROOT_PATH, "DB")

if ENV['BBTOOLS_PATH']
   BBPATH = ENV['BBTOOLS_PATH']
else
   BBPATH = File.expand_path(File.dirname(%x[which bbmap.sh]))
end

OUTPUT_PATH = File.join(ROOT_PATH,'temp')
DEFAULT_FINAL_OUTPUT_PATH = OUTPUT_PATH

FileUtils.rm_rf OUTPUT_PATH if Dir.exist?(OUTPUT_PATH)
Dir.mkdir(OUTPUT_PATH)

require 'seqtrimbb'
require 'minitest/autorun'
require 'fileutils'
require 'plugin_manager.rb'
require 'bbtools.rb'
require 'databases_support_handler.rb'
#require 'params.rb'

#Utilities
class Hash
   def slice(*keys)
           ::Hash[[keys, self.values_at(*keys)].transpose]
   end
   def except(*keys)
           dup.except!(*keys)
   end
   def except!(*keys)
           keys.each { |key| delete(key) }
           self
   end
end