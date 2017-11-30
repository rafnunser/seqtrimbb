require 'test_helper'

class PluginVectorsTest < Minitest::Test

      def test_plugin_vectors

             db = 'vectors'
          #SETUP
             setup_databases   
             db_path = File.join(OUTPUT_PATH,'DB')
           #PARAMS
             nativelibdir = File.join(BBPATH,'jni')
             classp = File.join(BBPATH,'current')
             bbtools = BBtools.new(BBPATH)
             base_ram = 720 
             stbb_db = DatabasesSupportHandler.new({:workers => 1},db_path,bbtools)
             stbb_db.init_internal({:databases_action => 'replace', :databases_list => ['vectors']})
             stbb_db.maintenance_internal({:check_db => true})
             args = ['-w','1','-t',File.join(ROOT_PATH,"files","faketemplate.txt") ]
             options = OptionsParserSTBB.parse(args)
             params = Params.new(options,bbtools)
             params.set_param('plugin_list','PluginVectors')
             vectors_db = File.join(db_path,'fastas/vectors/vectors.fasta.gz')
             r_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"vectors_3_trimming_stats.txt")
             l_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"vectors_5_trimming_stats.txt")
             r_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"vectors_3_trimming_stats_cmd.txt")
             l_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"vectors_5_trimming_stats_cmd.txt")
             c_outstats = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db}_vectors_filtering_stats.txt")
             c_outstats2 = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{db}_vectors_filtering_stats_cmd.txt")
             ram = (stbb_db.get_info(db,'index_size')/2.0**20).round(0) + base_ram  
          # Adding aditional params
             params.set_param('sample_type','paired')
             params.set_param('vectors_trimming_aditional_params','add_param=test')
             params.set_param('vectors_filtering_aditional_params','add_param=test')
             default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 't'}
             bbtools.store_default(default_options)             
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 in=stdin.fastq int=t minratio=0.80 path=#{stbb_db.get_info(db,'index')} refstats=#{c_outstats} add_param=test outu=stdout.fastq t=1 -Xmx#{ram}m 2> #{c_outstats2} | java -Djava.library.path=/home/rafa/opt/bbmap/jni -ea -cp /home/rafa/opt/bbmap/current jgi.BBDukF in=stdin.fastq out=stdout.fastq int=t ref=#{vectors_db} k=31 mink=11 hdist=1 ktrim=r stats=#{r_outstats} tbo tpe add_param=test restrictleft=58 restrictright=58 t=1 -Xmx51m 2> #{r_outstats2} | java -Djava.library.path=/home/rafa/opt/bbmap/jni -ea -cp /home/rafa/opt/bbmap/current jgi.BBDukF in=stdin.fastq out=stdout.fastq int=t ref=#{vectors_db} k=31 mink=11 hdist=1 ktrim=l stats=#{l_outstats} tbo tpe add_param=test restrictleft=58 restrictright=58 t=1 -Xmx51m 2> #{l_outstats2}"
             manager = PluginManager.new('PluginVectors',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginVectors']['cmd']
             assert_equal(result,plugin_cmd)           
           # Triming mode: Left
             params.set_param('vectors_trimming_position','left')
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 in=stdin.fastq int=t minratio=0.80 path=#{stbb_db.get_info(db,'index')} refstats=#{c_outstats} add_param=test outu=stdout.fastq t=1 -Xmx#{ram}m 2> #{c_outstats2} | java -Djava.library.path=/home/rafa/opt/bbmap/jni -ea -cp /home/rafa/opt/bbmap/current jgi.BBDukF in=stdin.fastq out=stdout.fastq int=t ref=#{vectors_db} k=31 mink=11 hdist=1 ktrim=l stats=#{l_outstats} tbo tpe add_param=test restrictleft=58 restrictright=58 t=1 -Xmx51m 2> #{l_outstats2}"             
             manager = PluginManager.new('PluginVectors',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginVectors']['cmd']
             assert_equal(result,plugin_cmd)
           # Triming mode: right
             params.set_param('vectors_trimming_position','right')                
             result = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 in=stdin.fastq int=t minratio=0.80 path=#{stbb_db.get_info(db,'index')} refstats=#{c_outstats} add_param=test outu=stdout.fastq t=1 -Xmx#{ram}m 2> #{c_outstats2} | java -Djava.library.path=/home/rafa/opt/bbmap/jni -ea -cp /home/rafa/opt/bbmap/current jgi.BBDukF in=stdin.fastq out=stdout.fastq int=t ref=#{vectors_db} k=31 mink=11 hdist=1 ktrim=r stats=#{r_outstats} tbo tpe add_param=test restrictleft=58 restrictright=58 t=1 -Xmx51m 2> #{r_outstats2}"             
             manager = PluginManager.new('PluginVectors',params,bbtools,stbb_db)
             manager.check_plugins_params   
             manager.execute_plugins
             plugin_cmd = manager.plugin_result['PluginVectors']['cmd']
             assert_equal(result,plugin_cmd)
           #CLEAN UP
             clean_up
               
      end

end