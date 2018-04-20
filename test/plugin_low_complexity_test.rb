require 'test_helper'

class PluginLowComplexityTest < Minitest::Test

      def test_plugin_lowcomplexity

           #SETUP
             setup_temp
             nativelibdir = File.join(BBPATH,'jni')
             classp = File.join(BBPATH,'current')
             bbtools = BBtools.new(BBPATH)
             stbb_db = DatabasesSupportHandler.new({:workers => 1},'',bbtools)
             args = ['-w','1','-t',File.join(ROOT_PATH,"files","faketemplate.txt") ]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools) 
             params.set_param('plugin_list','PluginLowComplexity')
             outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"low_complexity_stats.txt")

           # Single-ended sample
             params.set_param('sample_type','single-ended')
             default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 'f'}
             bbtools.store_default(default_options)
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF t=1 -Xmx50m -Xms50m in=stdin.fastq out=stdout.fastq int=f entropy=0.01 entropywindow=50 minlength=50 2> #{outstats}"             
             manager = PluginManager.new('PluginLowComplexity',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginLowComplexity']['cmd']
             assert_equal(result,plugin_cmd)

           # Saving singles
             params.set_param('sample_type','paired')
             params.set_param('save_unpaired',true)
             default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 't'}
             bbtools.store_default(default_options)
             outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_low_complexity_filtering.fastq.gz")
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF t=1 -Xmx50m -Xms50m in=stdin.fastq out=stdout.fastq int=t entropy=0.01 entropywindow=50 minlength=50 outs=#{outsingles} 2> #{outstats}"             
             manager = PluginManager.new('PluginLowComplexity',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginLowComplexity']['cmd']
             assert_equal(result,plugin_cmd)

          # Minlength < 50
             params.set_param('minlength',40)
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF t=1 -Xmx50m -Xms50m in=stdin.fastq out=stdout.fastq int=t entropy=0.01 entropywindow=40 minlength=40 outs=#{outsingles} 2> #{outstats}"             
             manager = PluginManager.new('PluginLowComplexity',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginLowComplexity']['cmd']
             assert_equal(result,plugin_cmd)

          #Aditional params
             params.set_param('low_complexity_aditional_params','add_param=test')
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF t=1 -Xmx50m -Xms50m in=stdin.fastq out=stdout.fastq int=t entropy=0.01 entropywindow=40 minlength=40 outs=#{outsingles} add_param=test 2> #{outstats}"             
             manager = PluginManager.new('PluginLowComplexity',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginLowComplexity']['cmd']
             assert_equal(result,plugin_cmd)
           #CLEAN UP
            clean_up

      end

end