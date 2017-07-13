require 'test_helper'

class PluginInputTest < Minitest::Test

  def test_plugin_input

    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')
    max_ram = '1g'
    cores = '1'
    sample_type = 'paired'
    file1 = File.join(RT_PATH,"DB","testfiles","testfile_1.fastq.gz")
    file2 = File.join(RT_PATH,"DB","testfiles","testfile_2.fastq.gz")
    file_single = File.join(RT_PATH,"DB","testfiles","testfile_single.fastq.gz")
    file_interleaved = File.join(RT_PATH,"DB","testfiles","testfile_interleaved.fastq.gz")

    options = {}

    options['file'] = [file1,file2]
    options['max_ram'] = max_ram
    options['workers'] = cores

    outstats = File.join(File.expand_path(OUTPUT_PATH),"input_stats.txt")

    plugin_list = 'PluginReadInputBb'

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    params = Params.new(faketemplate,options)

 # Interleaved sample

   options['file'] = [file_interleaved]

   params = Params.new(faketemplate,options)

   result = "java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores} in=#{file_interleaved} int=t out=stdout.fastq 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

 # Paired sample

   options['file'] = [file1,file2]

   params = Params.new(faketemplate,options)

   result = "java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores} in=#{file1} in2=#{file2} out=stdout.fastq 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

 # Fasta sample without qual

   file1 = File.join(RT_PATH,"DB","testfiles","testfile_1.fasta.gz")
   file2 = File.join(RT_PATH,"DB","testfiles","testfile_2.fasta.gz")
   options['file'] = [file1,file2]

   params = Params.new(faketemplate,options)

   result = "java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores} in=#{file1} in2=#{file2} q=40 out=stdout.fastq 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

 # Fasta sample with qual

   qual1 = File.join(RT_PATH,"DB","testfiles","qualfile_1.qual.gz")
   qual2 = File.join(RT_PATH,"DB","testfiles","qualfile_2.qual.gz")
   options['qual'] = [qual1,qual2]

   params = Params.new(faketemplate,options)

   result = "java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores} in=#{file1} in2=#{file2} qfin=#{qual1} qfin2=#{qual2} out=stdout.fastq 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

 # Single-ended sample

   options['file'] = [file_single]

   params = Params.new(faketemplate,options)

   result = "java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores} in=#{file_single} out=stdout.fastq 2> #{outstats}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugins()

   assert_equal(result,test[0])

  end

end

