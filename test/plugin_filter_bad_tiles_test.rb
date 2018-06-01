require 'test_helper'

class PluginFilterBadTilesTest < Minitest::Test

      def test_plugin_filter_bad_tiles

           #SETUP
             setup_temp
             file_interleaved = File.join(ROOT_PATH,"files","testfiles","testfile_interleaved.fastq.gz")
             nativelibdir = File.join(BBPATH,'jni')
             classp = File.join(BBPATH,'current')
             bbtools = BBtools.new(BBPATH)
             stbb_db = DatabasesSupportHandler.new({:workers => 1},'',bbtools)
             args = ['-w','1','-t',File.join(ROOT_PATH,"files","faketemplate.txt"),'-Q',file_interleaved]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools) 
             params.set_param('plugin_list','PluginFilterBadTiles')
             outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"filter_bad_tiles_stats.txt")
             outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"filter_bad_tiles_stats_cmd.txt")

          #Aditional params
             params.set_param('filter_bad_tiles_aditional_params','add_param=test')
             result = "java -ea -cp #{classp} hiseq.AnalyzeFlowCell t=1 -Xmx260m -Xms260m in=#{file_interleaved} out=stdout.fastq int=t xsize=500 ysize=500 target=800 dump=#{outstats} add_param=test 2> #{outstats2}"             
             manager = PluginManager.new('PluginFilterBadTiles',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginFilterBadTiles']['cmd']
             assert_equal(result,plugin_cmd)

           #CLEAN UP
             clean_up

      end

end