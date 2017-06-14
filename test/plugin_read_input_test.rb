require 'test_helper'

class PluginInputTest < Minitest::Test

  def test_plugin_input


    options = {}

    options['max_ram'] = '1G'
    options['workers'] = '1'
    options['sample_type'] = 'paired'
    options['file_format'] = 'fastq'

    outstats = File.join(File.expand_path(OUTPUT_PATH),"input_stats.txt")

    plugin_list = 'PluginReadInputBb'

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    params = Params.new(faketemplate,options)

 # Single-ended sample

    options['sample_type'] = 'single-ended'

    params = Params.new(faketemplate,options)

    file = "testfile.fastq"

    $SAMPLEFILES = []

    $SAMPLEFILES[0] = file

    result = "reformat.sh -Xmx1G t=1 in=#{file} out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

 # Interleaved sample

   options['sample_type'] = 'interleaved'

   params = Params.new(faketemplate,options)

   file = "testfile.fastq"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file

   result = "reformat.sh -Xmx1G t=1 in=#{file} int=t out=stdout.fastq 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

 # Paired sample

   options['sample_type'] = 'paired'

   params = Params.new(faketemplate,options)

   file1 = "testfile_1.fastq"
   file2 = "testfile_2.fastq"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file1
   $SAMPLEFILES[1] = file2

   result = "reformat.sh -Xmx1G t=1 in=#{file1} in2=#{file2} out=stdout.fastq 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

 # Fasta sample without qual

   options['sample_type'] = 'paired'
   options['file_format'] = 'fasta'

   params = Params.new(faketemplate,options)

   file1 = "testfile_1.fasta"
   file2 = "testfile_2.fasta"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file1
   $SAMPLEFILES[1] = file2

   result = "reformat.sh -Xmx1G t=1 in=#{file1} in2=#{file2} q=40 out=stdout.fastq 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

 # Fasta sample with qual

   options['sample_type'] = 'paired'
   options['file_format'] = 'fasta'

   params = Params.new(faketemplate,options)

   file1 = "testfile_1.fasta"
   file2 = "testfile_2.fasta"
   qual1 = "testqual_1.qual"
   qual2 = "testqual_2.qual"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file1
   $SAMPLEFILES[1] = file2

   $SAMPLEQUALS = []

   $SAMPLEQUALS[0] = qual1
   $SAMPLEQUALS[1] = qual2

   result = "reformat.sh -Xmx1G t=1 in=#{file1} in2=#{file2} qual=#{qual1} qual1=#{qual2} out=stdout.fastq 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

  end

end

