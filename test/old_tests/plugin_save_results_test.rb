require 'test_helper'

class PluginOutputTest < Minitest::Test

  def test_plugin_save

    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')
    max_ram = '1g'
    cores = '1'
    sample_type = 'paired'
    minlength = 50
    file1 = File.join(RT_PATH,"DB","testfiles","testfile_1.fastq.gz")
    file2 = File.join(RT_PATH,"DB","testfiles","testfile_2.fastq.gz")
    file_interleaved = File.join(RT_PATH,"DB","testfiles","testfile_interleaved.fastq.gz")
    file_single = File.join(RT_PATH,"DB","testfiles","testfile_single.fastq.gz")

    suffix = '.fastq'

    outfiles = [File.join(File.expand_path(OUTPUT_PATH),"paired_1#{suffix}"),File.join(File.expand_path(OUTPUT_PATH),"paired_2#{suffix}")]
    outfile_interleaved = [File.join(File.expand_path(OUTPUT_PATH),"interleaved#{suffix}")]
    outfile_single = [File.join(File.expand_path(OUTPUT_PATH),"sequences_#{suffix}")]

    options = {}

    options['max_ram'] = max_ram
    options['workers'] = cores
    options['minlength'] = minlength
    options['ext_cmd'] = nil

    outstats = File.join(File.expand_path(OUTPUT_PATH),"output_stats.txt")

    plugin_list = 'PluginSaveResultsBb'

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

 # Interleaved sample

   options['file'] = [file_interleaved]

   params = Params.new(faketemplate,options)

   result = "java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores} minlength=#{minlength} in=stdin.fastq int=t out=#{outfile_interleaved[0]} 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

 # Paired sample

   options['file'] = [file1,file2]

   params = Params.new(faketemplate,options)

   result = "java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores} minlength=#{minlength} in=stdin.fastq int=t out=#{outfiles[0]} out2=#{outfiles[1]} 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

 # Single-ended sample

   options['file'] = [file_single]

   params = Params.new(faketemplate,options)

   result = "java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores} minlength=#{minlength} in=stdin.fastq out=#{outfile_single[0]} 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

  end

end
