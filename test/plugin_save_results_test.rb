require 'test_helper'

class PluginOutputTest < Minitest::Test

      def test_plugin_save

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
             outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"output_stats.txt")
             suffix = '.fastq.gz'
             outfiles = [File.join(File.expand_path(OUTPUT_PATH),"paired_1#{suffix}"),File.join(File.expand_path(OUTPUT_PATH),"paired_2#{suffix}")]
             outfile_interleaved = File.join(File.expand_path(OUTPUT_PATH),"interleaved#{suffix}")
             outfile_single = File.join(File.expand_path(OUTPUT_PATH),"sequences_#{suffix}")             
          # Interleaved sample
             args = ['-w','1','-Q',file_interleaved,'-t',File.join(ROOT_PATH,"files","faketemplate.txt")]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginSaveResultsBb')
             result = "java -ea -cp #{classp} jgi.ReformatReads in=stdin.fastq out=#{outfile_interleaved} int=t minlength=50 t=1 -Xmx50m 2> #{outstats}"
             manager = PluginManager.new('PluginSaveResultsBb',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginSaveResultsBb']['cmd']
             assert_equal(result,plugin_cmd)
          # Paired sample
             args = ['-w','1','-Q',"#{file1},#{file2}",'-t',File.join(ROOT_PATH,"files","faketemplate.txt")]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginSaveResultsBb')
             result = "java -ea -cp #{classp} jgi.ReformatReads in=stdin.fastq out=#{outfiles[0]} int=t out2=#{outfiles[1]} minlength=50 t=1 -Xmx50m 2> #{outstats}"
             manager = PluginManager.new('PluginSaveResultsBb',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginSaveResultsBb']['cmd']
             assert_equal(result,plugin_cmd)
          # Single-ended sample
             args = ['-w','1','-Q',file_single,'-t',File.join(ROOT_PATH,"files","faketemplate.txt")]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginSaveResultsBb')
             result = "java -ea -cp #{classp} jgi.ReformatReads in=stdin.fastq out=#{outfile_single} int=f minlength=50 t=1 -Xmx50m 2> #{outstats}"
             manager = PluginManager.new('PluginSaveResultsBb',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginSaveResultsBb']['cmd']
             assert_equal(result,plugin_cmd)
          #Minlength
             params.set_param('minlength',70)
             result = "java -ea -cp #{classp} jgi.ReformatReads in=stdin.fastq out=#{outfile_single} int=f minlength=70 t=1 -Xmx50m 2> #{outstats}"
             manager = PluginManager.new('PluginSaveResultsBb',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginSaveResultsBb']['cmd']
             assert_equal(result,plugin_cmd)
          #No write in gzip
             args = ['-w','1','-Q',file_single,'-t',File.join(ROOT_PATH,"files","faketemplate.txt"),'-z']
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginSaveResultsBb')
             outfile_single = File.join(File.expand_path(OUTPUT_PATH),"sequences_.fastq")             
             result = "java -ea -cp #{classp} jgi.ReformatReads in=stdin.fastq out=#{outfile_single} int=f minlength=50 t=1 -Xmx50m 2> #{outstats}"
             manager = PluginManager.new('PluginSaveResultsBb',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginSaveResultsBb']['cmd']
             assert_equal(result,plugin_cmd)
          #Ext cmd
             args = ['-w','1','-Q',file_single,'-t',File.join(ROOT_PATH,"files","faketemplate.txt"),'--external_cmd','mock']
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginSaveResultsBb')
             outfile_single = File.join(File.expand_path(OUTPUT_PATH),"sequences_.fastq")             
             result = "java -ea -cp #{classp} jgi.ReformatReads in=stdin.fastq out=stdout.fastq int=f minlength=50 t=1 -Xmx50m 2> #{outstats}"
             manager = PluginManager.new('PluginSaveResultsBb',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginSaveResultsBb']['cmd']
             assert_equal(result,plugin_cmd)
           #CLEAN UP
               clean_up

      end

end
