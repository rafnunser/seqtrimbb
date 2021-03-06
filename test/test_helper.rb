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
# Finds classes in 'classes/params' folder
$: << File.expand_path(File.join(SEQTRIM_PATH,'lib','seqtrimbb','classes','params'))
# Finds classes in 'plugins' folder
$: << File.expand_path(File.join(SEQTRIM_PATH,'lib','seqtrimbb','plugins'))

ROOT_PATH=File.join(File.dirname(__FILE__))

FILES_PATH = File.join(ROOT_PATH, "files")

if ENV['BBTOOLS_PATH']
   BBPATH = ENV['BBTOOLS_PATH']
else
   BBPATH = File.expand_path(File.dirname(%x[which bbmap.sh]))
end

OUTPUT_PATH = File.join(ROOT_PATH,'temp')
DEFAULT_FINAL_OUTPUT_PATH = OUTPUT_PATH

require 'seqtrimbb'
require 'minitest/autorun'
require 'fileutils'
require 'plugin_manager.rb'
require 'plugin.rb'
require 'json'
require 'bbtools.rb'
require 'databases_support_handler.rb'
require 'params.rb'
require 'optparse'
require 'options_stbb.rb'
require 'plugin_merger.rb'
require 'zlib'

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
class String  
   def decamelize 
           self.to_s. 
                   gsub(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2'). 
                   gsub(/([a-z]+)([A-Z\d])/, '\1_\2'). 
                   gsub(/([A-Z]{2,})(\d+)/i, '\1_\2'). 
                   gsub(/(\d+)([a-z])/i, '\1_\2'). 
                   gsub(/(.+?)\&(.+?)/, '\1_&_\2'). 
                   gsub(/\s/, '_').downcase 
   end
end
# PATCH OLD_RUBY
## DIG
module RubyDig
       def dig(key, *rest)
               if value = (self[key] rescue nil)
                       if rest.empty?
                               value
                       elsif value.respond_to?(:dig)
                               value.dig(*rest)
                       end
               end
       end
end
##PATCH!
if RUBY_VERSION < '2.3'
       Array.send(:include, RubyDig)
       Hash.send(:include, RubyDig)
end
def setup_temp

       FileUtils.rm_rf OUTPUT_PATH if Dir.exist?(OUTPUT_PATH)
       Dir.mkdir(OUTPUT_PATH) if !Dir.exist?(OUTPUT_PATH)

end

def setup_databases

       setup_temp
       source_path = FILES_PATH
       db_path = File.join(OUTPUT_PATH,'DB')
       Dir.mkdir(db_path)
       FileUtils.cp_r File.join(source_path,'fastas'),db_path
       Dir.mkdir(File.join(db_path,'status_info'))
       FileUtils.cp File.join(db_path,'fastas','repository_databases_info.json'),File.join(db_path,'status_info')

end

def clean_up

       FileUtils.rm_rf OUTPUT_PATH if Dir.exist?(OUTPUT_PATH)    
     
end
