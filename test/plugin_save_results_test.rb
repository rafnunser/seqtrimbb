require 'test_helper'

class PluginOutputTest < Minitest::Test

  def test_plugin_save

    options = {}

    options['max_ram'] = '1G'
    options['workers'] = '1'
    options['sample_type'] = 'paired'
    options['minlength'] = 50

    minlength = "minlength=50"

    outstats = File.join(File.expand_path(OUTPUT_PATH),"output_stats.txt")

    plugin_list = 'PluginSaveResultsBb'

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    params = Params.new(faketemplate,options)

    output = File.expand_path(OUTPUT_PATH)

 # Single-ended sample

   options['sample_type'] = 'single-ended'

   params = Params.new(faketemplate,options)

   file = "testoutfile.fastq.gz"

   $OUTPUTFILES = []

   $OUTPUTFILES[0] = file

   result = "reformat.sh -Xmx1G t=1 #{minlength} in=stdin.fastq out=#{output}/#{file} 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

 # Interleaved sample

   options['sample_type'] = 'interleaved'

   params = Params.new(faketemplate,options)

   file = "testoutfile.fastq.gz"

   $OUTPUTFILES = []

   $OUTPUTFILES[0] = file

   result = "reformat.sh -Xmx1G t=1 #{minlength} in=stdin.fastq int=t out=#{output}/#{file} 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

 # Paired sample

   options['sample_type'] = 'paired'

   params = Params.new(faketemplate,options)

   file1 = "testoutfile_1.fastq.gz"
   file2 = "testoutfile_2.fastq.gz"

   $OUTPUTFILES = []

   $OUTPUTFILES[0] = file1
   $OUTPUTFILES[1] = file2

   result = "reformat.sh -Xmx1G t=1 #{minlength} in=stdin.fastq int=t out=#{output}/#{file1} out2=#{output}/#{file2} 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

  end

end
