require 'test_helper'

class PluginAdaptersTest < Minitest::Test

      def test_plugin_adapters
          
          #SETUP
             setup_databases   
             db_path = File.join(OUTPUT_PATH,'DB')
           #PARAMS
             adapters_db = File.join(db_path,'fastas/adapters/adapters.fasta.gz')
             r_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"adapters_3_trimming_stats.txt")
             l_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"adapters_5_trimming_stats.txt")
             r_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"adapters_3_trimming_stats_cmd.txt")
             l_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"adapters_5_trimming_stats_cmd.txt")
             nativelibdir = File.join(BBPATH,'jni')
             classp = File.join(BBPATH,'current')
             bbtools = BBtools.new(BBPATH)
             stbb_db = DatabasesSupportHandler.new({:workers => 1},db_path,bbtools)
             stbb_db.init_internal({:databases_action => 'replace', :databases_list => ['adapters','contaminants']})
             stbb_db.maintenance_internal({:check_db => true})
             args = ['-w','1','-t',File.join(ROOT_PATH,"files","faketemplate.txt") ]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginAdapters')

           # Single-ended sample
             params.set_param('sample_type','single-ended')
             default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 'f'}
             bbtools.store_default(default_options)
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF in=stdin.fastq out=stdout.fastq int=f ref=#{adapters_db} k=15 mink=8 hdist=1 ktrim=r stats=#{r_outstats} t=1 -Xmx100m 2> #{r_outstats2} | java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF in=stdin.fastq out=stdout.fastq int=f ref=#{adapters_db} k=21 mink=14 hdist=1 ktrim=l stats=#{l_outstats} t=1 -Xmx100m 2> #{l_outstats2}"             
             manager = PluginManager.new('PluginAdapters',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginAdapters']['cmd']
             assert_equal(result,plugin_cmd)
           # Saving singles
             params.set_param('save_unpaired','true')
             outsingles3 = File.join(File.expand_path(OUTPUT_PATH),"singles_adapters_3_trimming.fastq.gz")
             outsingles5 = File.join(File.expand_path(OUTPUT_PATH),"singles_adapters_5_trimming.fastq.gz")
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF in=stdin.fastq out=stdout.fastq int=f ref=#{adapters_db} k=15 mink=8 hdist=1 ktrim=r stats=#{r_outstats} outs=#{outsingles3} t=1 -Xmx100m 2> #{r_outstats2} | java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF in=stdin.fastq out=stdout.fastq int=f ref=#{adapters_db} k=21 mink=14 hdist=1 ktrim=l stats=#{l_outstats} outs=#{outsingles5} t=1 -Xmx100m 2> #{l_outstats2}"
             manager = PluginManager.new('PluginAdapters',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginAdapters']['cmd']
             assert_equal(result,plugin_cmd)
             params.set_param('save_unpaired','false')           
           # Triming mode: Left
             params.set_param('adapters_trimming_position','left')
             params.set_param('sample_type','paired')
             default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 't'}
             bbtools.store_default(default_options)             
             result = "java -Djava.library.path=/home/rafa/opt/bbmap/jni -ea -cp /home/rafa/opt/bbmap/current jgi.BBDukF in=stdin.fastq out=stdout.fastq int=t ref=#{adapters_db} k=21 mink=14 hdist=1 ktrim=l stats=#{l_outstats} tbo tpe t=1 -Xmx100m 2> #{l_outstats2}"             
             manager = PluginManager.new('PluginAdapters',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginAdapters']['cmd']
             assert_equal(result,plugin_cmd)
           # Triming mode: right
             params.set_param('adapters_trimming_position','right')             
             result = "java -Djava.library.path=/home/rafa/opt/bbmap/jni -ea -cp /home/rafa/opt/bbmap/current jgi.BBDukF in=stdin.fastq out=stdout.fastq int=t ref=#{adapters_db} k=15 mink=8 hdist=1 ktrim=r stats=#{r_outstats} tbo tpe t=1 -Xmx100m 2> #{r_outstats2}"             
             manager = PluginManager.new('PluginAdapters',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginAdapters']['cmd']
             assert_equal(result,plugin_cmd)           
           # Trimming mode: paired without merging
             params.set_param('adapters_merging_pairs_trimming','false')
             result = "java -Djava.library.path=/home/rafa/opt/bbmap/jni -ea -cp /home/rafa/opt/bbmap/current jgi.BBDukF in=stdin.fastq out=stdout.fastq int=t ref=#{adapters_db} k=15 mink=8 hdist=1 ktrim=r stats=#{r_outstats} t=1 -Xmx100m 2> #{r_outstats2}"             
             manager = PluginManager.new('PluginAdapters',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginAdapters']['cmd']
             assert_equal(result,plugin_cmd)           
           # Adding some additional params
             params.set_param('adapters_aditional_params',"add_param=test")
             params.set_param('adapters_merging_pairs_trimming','false')
             result = "java -Djava.library.path=/home/rafa/opt/bbmap/jni -ea -cp /home/rafa/opt/bbmap/current jgi.BBDukF in=stdin.fastq out=stdout.fastq int=t ref=#{adapters_db} k=15 mink=8 hdist=1 ktrim=r stats=#{r_outstats} add_param=test t=1 -Xmx100m 2> #{r_outstats2}"             
             manager = PluginManager.new('PluginAdapters',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginAdapters']['cmd']
             assert_equal(result,plugin_cmd)
           # Multiple-file database
             adapters_db = Dir[File.join(db_path,'fastas/contaminants/','*.fasta*')].sort.join(",")
             params.set_param('adapters_db','contaminants')
             result = "java -Djava.library.path=/home/rafa/opt/bbmap/jni -ea -cp /home/rafa/opt/bbmap/current jgi.BBDukF in=stdin.fastq out=stdout.fastq int=t ref=#{adapters_db} k=15 mink=8 hdist=1 ktrim=r stats=#{r_outstats} add_param=test t=1 -Xmx100m 2> #{r_outstats2}"             
             manager = PluginManager.new('PluginAdapters',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginAdapters']['cmd']
             assert_equal(result,plugin_cmd)
           #CLEAN UP
               clean_up
               
      end

end
