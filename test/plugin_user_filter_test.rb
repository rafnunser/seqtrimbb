require 'test_helper'

class PluginUserFilterTest < Minitest::Test

      def test_plugin_user_filter

          #SETUP
             setup_databases   
             db_path = File.join(OUTPUT_PATH,'DB')
           #PARAMS
             db = 'contaminants'
             nativelibdir = File.join(BBPATH,'jni')
             classp = File.join(BBPATH,'current')
             bbtools = BBtools.new(BBPATH)
             base_ram = 720
             stbb_db = DatabasesSupportHandler.new({:workers => 1},db_path,bbtools)
             stbb_db.init_internal({:databases_action => 'replace', :databases_list => ['contaminants','vectors']})
             stbb_db.maintenance_internal({:check_db => true})
             args = ['-w','1','-t',File.join(ROOT_PATH,"files","faketemplate.txt") ]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginUserFilter')
             params.set_param('user_filter_db','contaminants')
             outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"contaminants_user_filter_filtering_stats.txt")
             outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"contaminants_user_filter_filtering_stats_cmd.txt")
             output = File.join(File.expand_path(OUTPUT_PATH),"filtered_files")
             ram = (stbb_db.get_info(db,'index_size')/2.0**20).round(0) + base_ram
           #WITHOUT SPECIES
             default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 't'}
             bbtools.store_default(default_options)             
             manager = PluginManager.new('PluginUserFilter',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginUserFilter']['cmd']
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 in=stdin.fastq int=t minratio=0.56 path=#{stbb_db.get_info(db,'index')} refstats=#{outstats} outu=stdout.fastq basename=#{output}/%_pre_out.fastq.gz t=1 -Xmx#{ram}m 2> #{outstats2}"
             assert_equal(result,plugin_cmd)
           # Two species
             params.set_param('user_filter_species','Contaminant one,Contaminant two')
             manager = PluginManager.new('PluginUserFilter',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginUserFilter']['cmd']
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 in=stdin.fastq int=t minratio=0.56 path=#{stbb_db.get_info(db,'index')} refstats=#{outstats} outu=stdout.fastq out_Contaminant_one=#{output}/Contaminant_one_pre_out.fastq.gz out_Contaminant_two=#{output}/Contaminant_two_pre_out.fastq.gz t=1 -Xmx#{ram}m 2> #{outstats2}"
             assert_equal(result,plugin_cmd)
           # External database
             db = File.join(db_path,'fastas/contaminants')
             params.set_param('user_filter_db',db) 
             manager = PluginManager.new('PluginUserFilter',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginUserFilter']['cmd']
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 in=stdin.fastq int=t minratio=0.56 path=#{stbb_db.get_info(db,'index')} refstats=#{outstats} outu=stdout.fastq out_Contaminant_one=#{output}/Contaminant_one_pre_out.fastq.gz out_Contaminant_two=#{output}/Contaminant_two_pre_out.fastq.gz t=1 -Xmx#{ram}m 2> #{outstats2}"
             assert_equal(result,plugin_cmd)             
           #CLEAN UP
               clean_up
               
      end

end
