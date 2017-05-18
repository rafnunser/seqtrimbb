$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

ROOT_PATH=File.join(File.dirname(__FILE__),'seqtrimbb')

$DB_PATH = File.expand_path(File.join(ROOT_PATH.split("/").drop(2), "test/DB"))

OUTPUT_PATH = "/test/testoutput"

require 'seqtrimbb'

require 'minitest/autorun'
