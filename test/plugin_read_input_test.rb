require 'test_helper'

class PluginInputTest < Minitest::Test

      def test_plugin_input

          #SETUP
             setup_temp 
             db_path = File.join(OUTPUT_PATH,'DB') 
             classp = File.join(BBPATH,'current')
             bbtools = BBtools.new(BBPATH)
             stbb_db = DatabasesSupportHandler.new({:workers => 1},db_path,bbtools)
             file1 = File.join(ROOT_PATH,"files","testfiles","testfile_1.fastq.gz")
             file2 = File.join(ROOT_PATH,"files","testfiles","testfile_2.fastq.gz")
             file_single = File.join(ROOT_PATH,"files","testfiles","testfile_single.fastq.gz")
             file_interleaved = File.join(ROOT_PATH,"files","testfiles","testfile_interleaved.fastq.gz")
             outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"input_stats.txt")

          # Interleaved sample
             args = ['-w','1','-Q',file_interleaved,'-t',File.join(ROOT_PATH,"files","faketemplate.txt")]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginReadInputBb')
             result = "java -ea -cp #{classp} jgi.ReformatReads t=1 -Xmx50m in=#{file_interleaved} out=stdout.fastq int=t 2> #{outstats}"
             manager = PluginManager.new('PluginReadInputBb',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginReadInputBb']['cmd']
             assert_equal(result,plugin_cmd)
          # Paired sample
             args = ['-w','1','-Q',"#{file1},#{file2}",'-t',File.join(ROOT_PATH,"files","faketemplate.txt")]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginReadInputBb')
             result = "java -ea -cp #{classp} jgi.ReformatReads t=1 -Xmx50m in=#{file1} out=stdout.fastq int=f in2=#{file2} 2> #{outstats}"
             manager = PluginManager.new('PluginReadInputBb',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginReadInputBb']['cmd']
             assert_equal(result,plugin_cmd)
          # Single-ended sample
             args = ['-w','1','-Q',file_single,'-t',File.join(ROOT_PATH,"files","faketemplate.txt")]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginReadInputBb')
             result = "java -ea -cp #{classp} jgi.ReformatReads t=1 -Xmx50m in=#{file_single} out=stdout.fastq int=f 2> #{outstats}"
             manager = PluginManager.new('PluginReadInputBb',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginReadInputBb']['cmd']
             assert_equal(result,plugin_cmd)
          # Fasta without qual
             ffile1 = File.join(ROOT_PATH,"files","testfiles","testfile_1.fasta.gz")
             ffile2 = File.join(ROOT_PATH,"files","testfiles","testfile_2.fasta.gz")
             args = ['-w','1','-Q',"#{ffile1},#{ffile2}",'-t',File.join(ROOT_PATH,"files","faketemplate.txt")]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginReadInputBb')
             result = "java -ea -cp #{classp} jgi.ReformatReads t=1 -Xmx50m in=#{ffile1} out=stdout.fastq int=f in2=#{ffile2} q=40 2> #{outstats}"
             manager = PluginManager.new('PluginReadInputBb',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginReadInputBb']['cmd']
             assert_equal(result,plugin_cmd)             
          # Fasta with qual
             qual1 = File.join(ROOT_PATH,"files","testfiles","qualfile_1.qual.gz")
             qual2 = File.join(ROOT_PATH,"files","testfiles","qualfile_2.qual.gz")
             args = ['-w','1','-Q',"#{ffile1},#{ffile2}",'-q',"#{qual1},#{qual2}",'-t',File.join(ROOT_PATH,"files","faketemplate.txt")]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginReadInputBb')
             result = "java -ea -cp #{classp} jgi.ReformatReads t=1 -Xmx50m in=#{ffile1} out=stdout.fastq int=f in2=#{ffile2} qfin=#{qual1} qfin2=#{qual2} 2> #{outstats}"
             manager = PluginManager.new('PluginReadInputBb',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginReadInputBb']['cmd']
             assert_equal(result,plugin_cmd) 
           #CLEAN UP
               clean_up

      end

end

