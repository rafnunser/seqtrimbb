require 'test_helper'

class PluginQualityTest < Minitest::Test

      def test_plugin_quality

           #SETUP
             setup_temp
             nativelibdir = File.join(BBPATH,'jni')
             classp = File.join(BBPATH,'current')
             bbtools = BBtools.new(BBPATH)
             stbb_db = DatabasesSupportHandler.new({:workers => 1},'',bbtools)
             args = ['-w','1','-t',File.join(ROOT_PATH,"files","faketemplate.txt") ]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools) 
             params.set_param('plugin_list','PluginQuality')
             outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"quality_trimming_stats.txt")
  
           # Saving singles
             params.set_param('sample_type','paired')
             params.set_param('save_unpaired',true)
             default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 't'}
             bbtools.store_default(default_options)
             outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_quality_trimming.fastq.gz")
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF t=1 -Xmx50m -Xms50m in=stdin.fastq out=stdout.fastq int=t trimq=20 outs=#{outsingles} qtrim=rl 2> #{outstats}"             
             manager = PluginManager.new('PluginQuality',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginQuality']['cmd']
             assert_equal(result,plugin_cmd)

          #Aditional params
             params.set_param('quality_aditional_params','add_param=test')
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF t=1 -Xmx50m -Xms50m in=stdin.fastq out=stdout.fastq int=t trimq=20 outs=#{outsingles} qtrim=rl add_param=test 2> #{outstats}"             
             manager = PluginManager.new('PluginQuality',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginQuality']['cmd']
             assert_equal(result,plugin_cmd)

          #Trimming left
             params.set_param('quality_trimming_position','left')
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF t=1 -Xmx50m -Xms50m in=stdin.fastq out=stdout.fastq int=t trimq=20 outs=#{outsingles} qtrim=l add_param=test 2> #{outstats}"             
             manager = PluginManager.new('PluginQuality',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginQuality']['cmd']
             assert_equal(result,plugin_cmd)

          #Trimming right
             params.set_param('quality_trimming_position','right')
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF t=1 -Xmx50m -Xms50m in=stdin.fastq out=stdout.fastq int=t trimq=20 outs=#{outsingles} qtrim=r add_param=test 2> #{outstats}"             
             manager = PluginManager.new('PluginQuality',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginQuality']['cmd']
             assert_equal(result,plugin_cmd)
           #CLEAN UP
               clean_up

      end

end