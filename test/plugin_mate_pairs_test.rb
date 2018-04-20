require 'test_helper'

class PluginMatePairsTest < Minitest::Test

      def test_plugin_mate_pairs
         
          #SETUP
             setup_databases   
             db_path = File.join(OUTPUT_PATH,'DB')
          #PARAMS
             nativelibdir = File.join(BBPATH,'jni')
             classp = File.join(BBPATH,'current')
             bbtools = BBtools.new(BBPATH)
             stbb_db = DatabasesSupportHandler.new({:workers => 1},db_path,bbtools)
             args = ['-w','1','-t',File.join(ROOT_PATH,"files","faketemplate.txt") ]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginMatePairs')
             outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"LMP_splitting_stats.txt")
             outstats1 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"LMP_splitting_stats_cmd.txt")
             outstats3 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"LMP_mask_cmd.txt")

          # Default linker
             default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 't'}
             bbtools.store_default(default_options)             
             result = "java -ea -cp #{classp} jgi.SplitNexteraLMP t=1 -Xmx50m in=stdin.fastq out=stdout.fastq int=t outu=stdout.fastq stats=#{outstats} mask=t 2> #{outstats1}"
             manager = PluginManager.new('PluginMatePairs',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginMatePairs']['cmd']
             assert_equal(result,plugin_cmd)

          # User linker
             params.set_param('linker_literal_seq','MOCKSEQUENCE')
             default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 't'}
             bbtools.store_default(default_options)             
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF t=1 -Xmx50m -Xms50m in=stdin.fastq out=stdout.fastq int=t kmask=J k=19 mink=11 hdist=1 hdist2=0 literal=MOCKSEQUENCE 2> #{outstats3} | java -ea -cp #{classp} jgi.SplitNexteraLMP t=1 -Xmx50m in=stdin.fastq out=stdout.fastq int=t outu=stdout.fastq stats=#{outstats} 2> #{outstats1}"
             manager = PluginManager.new('PluginMatePairs',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginMatePairs']['cmd']
             assert_equal(result,plugin_cmd)
           #CLEAN UP
               clean_up
               
      end

end
