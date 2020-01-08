require 'test_helper'

class PluginPolyAtTest < Minitest::Test

      def test_plugin_polyat

           #SETUP
             setup_temp
             nativelibdir = File.join(BBPATH,'jni')
             classp = File.join(BBPATH,'current')
             bbtools = BBtools.new(BBPATH)
             stbb_db = DatabasesSupportHandler.new({:workers => 1},'',bbtools)
             args = ['-w','1','-t',File.join(ROOT_PATH,"files","faketemplate.txt") ]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools) 
             params.set_param('plugin_list','PluginPolyAt')
             outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"polyat_trimming_stats.txt")

           # Saving singles
             params.set_param('sample_type','paired')
             params.set_param('save_unpaired','true')
             default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 't'}
             bbtools.store_default(default_options)
             outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_polyat_trimming.fastq.gz")
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDuk t=1 -Xmx50m -Xms50m in=stdin.fastq out=stdout.fastq int=t trimpolya=9 outs=#{outsingles} 2> #{outstats}"             
             manager = PluginManager.new('PluginPolyAt',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginPolyAt']['cmd']
             assert_equal(result,plugin_cmd)

          #Aditional params
             params.set_param('polyat_aditional_params','add_param=test')
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDuk t=1 -Xmx50m -Xms50m in=stdin.fastq out=stdout.fastq int=t trimpolya=9 outs=#{outsingles} add_param=test 2> #{outstats}"             
             manager = PluginManager.new('PluginPolyAt',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginPolyAt']['cmd']
             assert_equal(result,plugin_cmd)
           #CLEAN UP
               clean_up

      end

end
