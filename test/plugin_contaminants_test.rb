require 'test_helper'

class PluginContaminantsTest < Minitest::Test

      def test_plugin_contaminants

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
             params.set_param('plugin_list','PluginContaminants')
             params.set_param('contaminants_db','contaminants')

             c_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db}_contaminants_filtering_stats.txt")
             c_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db}_contaminants_filtering_stats_cmd.txt")
             ram = (stbb_db.get_info(db,'index_size')/2.0**20).round(0) + base_ram
          # Aditional params
             params.set_param('contaminants_aditional_params','add_param=test')
             default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 't'}
             bbtools.store_default(default_options)             
             manager = PluginManager.new('PluginContaminants',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginContaminants']['cmd']
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 t=1 -Xmx#{ram}m in=stdin.fastq int=t minratio=0.56 path=#{stbb_db.get_info(db,'index')} refstats=#{c_outstats} add_param=test outu=stdout.fastq 2> #{c_outstats2}"
             assert_equal(result,plugin_cmd)
             params.set_param('contaminants_aditional_params',nil)
          # Exclude mode : species
             index_path = File.join(OUTPUT_PATH,'temp_indices','contaminants')
             db = "contaminants_excluding"
             db_name = 'contaminants_excluding'
             params.set_param('contaminants_decontamination_mode','exclude species')
             params.set_param('sample_species','Contaminant one')
             manager = PluginManager.new('PluginContaminants',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginContaminants']['cmd']
             c_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db}_contaminants_filtering_stats.txt")
             c_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db}_contaminants_filtering_stats_cmd.txt")
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 t=1 -Xmx#{ram}m in=stdin.fastq int=t minratio=0.56 path=#{stbb_db.get_info(db,'index')} refstats=#{c_outstats} outu=stdout.fastq 2> #{c_outstats2}"
             assert_equal(result,plugin_cmd)
          # Exclude mode :  genus
             index_path = File.join(OUTPUT_PATH,'temp_indices','contaminants')
             db = "contaminants_excluding_1"
             db_name = 'contaminants_excluding_1'
             params.set_param('contaminants_decontamination_mode','exclude genus')
             params.set_param('sample_species','Contaminant two')
             manager = PluginManager.new('PluginContaminants',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginContaminants']['cmd']
             c_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db}_contaminants_filtering_stats.txt")
             c_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db}_contaminants_filtering_stats_cmd.txt")
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 t=1 -Xmx#{ram}m in=stdin.fastq int=t minratio=0.56 path=#{stbb_db.get_info(db,'index')} refstats=#{c_outstats} outu=stdout.fastq 2> #{c_outstats2}"
             assert_equal(result,plugin_cmd)            
          # External single file database
             db = File.join(db_path,'fastas/contaminants','Contaminant_one.fasta.gz')
             params.set_param('contaminants_db',db)
             params.set_param('contaminants_decontamination_mode','regular')   
             manager = PluginManager.new('PluginContaminants',params,bbtools,stbb_db)
             manager.check_plugins_params
             db_name = stbb_db.get_info(db,'name')
             c_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db_name}_contaminants_filtering_stats.txt")
             c_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db_name}_contaminants_filtering_stats_cmd.txt")
             ram = (stbb_db.get_info(db,'index_size')/2.0**20).round(0) + base_ram             
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 t=1 -Xmx#{ram}m in=stdin.fastq int=t minratio=0.56 path=#{stbb_db.get_info(db,'index')} refstats=#{c_outstats} outu=stdout.fastq 2> #{c_outstats2}"             
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginContaminants']['cmd']
             assert_equal(result,plugin_cmd)
          # External database    
             db = File.join(db_path,'fastas','contaminants')
             params.set_param('contaminants_db',db)   
             manager = PluginManager.new('PluginContaminants',params,bbtools,stbb_db)
             manager.check_plugins_params
             db_name = stbb_db.get_info(db,'name')
             c_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db_name}_contaminants_filtering_stats.txt")
             c_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db_name}_contaminants_filtering_stats_cmd.txt")
             ram = (stbb_db.get_info(db,'index_size')/2.0**20).round(0) + base_ram             
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 t=1 -Xmx#{ram}m in=stdin.fastq int=t minratio=0.56 path=#{stbb_db.get_info(db,'index')} refstats=#{c_outstats} outu=stdout.fastq 2> #{c_outstats2}"             
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginContaminants']['cmd']
             assert_equal(result,plugin_cmd)
          # Two databases
             db = ['contaminants','vectors']
             params.set_param('contaminants_db','contaminants,vectors')
             c1_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db[0]}_contaminants_filtering_stats.txt")
             c1_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db[0]}_contaminants_filtering_stats_cmd.txt")
             c2_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db[1]}_contaminants_filtering_stats.txt")
             c2_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db[1]}_contaminants_filtering_stats_cmd.txt")
             ram1 = (stbb_db.get_info(db[0],'index_size')/2.0**20).round(0) + base_ram
             ram2 = (stbb_db.get_info(db[1],'index_size')/2.0**20).round(0) + base_ram
             manager = PluginManager.new('PluginContaminants',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginContaminants']['cmd']
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 t=1 -Xmx#{ram1}m in=stdin.fastq int=t minratio=0.56 path=#{stbb_db.get_info(db[0],'index')} refstats=#{c1_outstats} outu=stdout.fastq 2> #{c1_outstats2} | java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 t=1 -Xmx#{ram2}m in=stdin.fastq int=t minratio=0.56 path=#{stbb_db.get_info(db[1],'index')} refstats=#{c2_outstats} outu=stdout.fastq 2> #{c2_outstats2}"
             assert_equal(result,plugin_cmd)  
           #CLEAN UP
               clean_up
               
      end
  
end
