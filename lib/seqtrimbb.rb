require "seqtrimbb/version"

PATH_LIB=File.dirname(__FILE__)
interm=PATH_LIB.split("/")
interm.pop
SEQTRIM_PATH = File.join(interm)
ROOT_PATH=File.join(PATH_LIB,'seqtrimbb')

$: << File.expand_path(File.join(ROOT_PATH, 'classes'))

#finds the classes that were in the folder 'plugins'
$: << File.expand_path(File.join(ROOT_PATH, 'plugins'))

#finds the classes that were in the folder 'utils'
$: << File.expand_path(File.join(ROOT_PATH, 'utils'))

require 'fileutils'

require 'string_utils'

module Seqtrimbb
  # Your code goes here...
end
