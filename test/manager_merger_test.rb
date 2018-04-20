#######################################
# Test plugin manager and plugin merger
#######################################

require 'test_helper'

class ManagerMergerTest < Minitest::Test

      def test_merger

               plugins = ['PluginAdapters','PluginContaminants','PluginLowComplexity','PluginMatePairs','PluginPolyAt','PluginQuality','PluginUserFilter','PluginVectors']
               1.upto(plugins.count) do |i|
               	       plugins.combination(i).to_a.each do |combination|
               	       	       combination.permutation.to_a.each do |permutation|
                                       PluginMerger.new(['PluginReadInputBb'] + permutation + ['PluginSaveResultsBb'])
                               end              	       	
               	       end
               end
    
      end  

      def test_manager

           #OPTIONS/PARAMS/DATABASES
	           #Load options
	             args = ['-M','-w','12','-Q',File.join(ROOT_PATH,"files","testfiles","testfile_single.fastq.gz"),'-t',File.join(ROOT_PATH,"files","faketemplate.txt") ]
               options = OptionsParserSTBB.parse(args)
             #Load Databases and BBTOOLS
               setup_databases
               bbtools = BBtools.new(BBPATH)
             #Initialize databases object
               db_path = File.join(OUTPUT_PATH,'DB')
               stbb_db = DatabasesSupportHandler.new({:workers => 1},db_path,bbtools)
             #Init internal support
               stbb_db.init_internal({:databases_action => 'replace', :databases_list => Array.new})
             #Maintenance (test check)
               stbb_db.maintenance_internal({:check_db => true})
             #Init and load params
               params = Params.new(options,bbtools)
               params.check_param(pl_error = [],'plugin_list','PluginList','PluginContaminants,PluginQuality','Plugins applied to every sequence, separated by commas. Order is important')
             # Store default options from params in bbtools
               bbtools.store_default(params.get_param('default_options'))
           #INIT MANAGER
               plugin_manager = PluginManager.new(params.get_param('plugin_list'),params,bbtools,stbb_db)
               assert_equal(plugin_manager.plugin_names,['PluginReadInputBb','PluginContaminants','PluginQuality','PluginSaveResultsBb'])
           #CHECK PARAMS
               res = plugin_manager.check_plugins_params
               assert(res)
           #EXECUTE
               plugin_manager.execute_plugins
           #PIPE!
               piped_cmd = plugin_manager.pipe!
               #assert_equal(piped_cmd,str_cmd)
           #Make working directory and subdirectories
               [OUTPUT_PATH,File.join(OUTPUT_PATH,'plugins_logs')].map{ |d| Dir.mkdir(d) if !Dir.exist?(d) }
           #Call
               system(piped_cmd)
           #Extract stats!
               stats = {}
               plugin_manager.extract_stats(stats)         
           #WITHOUT MERGE
             #Load options
               args = ['-w','12','-Q',"#{File.join(ROOT_PATH,"files","testfiles","testfile_1.fastq.gz")},#{File.join(ROOT_PATH,"files","testfiles","testfile_2.fastq.gz")}",'-t',File.join(ROOT_PATH,"files","faketemplate.txt") ]
               options = OptionsParserSTBB.parse(args)           
             #Init and load params
               params = Params.new(options,bbtools)
               params.check_param(pl_error = [],'plugin_list','PluginList','PluginAdapters,PluginContaminants,PluginLowComplexity,PluginMatePairs,PluginPolyAt,PluginQuality,PluginUserFilter,PluginVectors','Plugins applied to every sequence, separated by commas. Order is important')
               params.set_param('user_filter_db','contaminants_seqtrim1')
             # Store default options from params in bbtools
               bbtools.store_default(params.get_param('default_options'))
           #INIT MANAGER
               plugin_manager = PluginManager.new(params.get_param('plugin_list'),params,bbtools,stbb_db)
               assert_equal(plugin_manager.plugin_names,['PluginReadInputBb','PluginAdapters','PluginContaminants','PluginLowComplexity','PluginMatePairs','PluginPolyAt','PluginQuality','PluginUserFilter','PluginVectors','PluginSaveResultsBb'])
           #CHECK PARAMS
               res = plugin_manager.check_plugins_params
               assert(res)
           #EXECUTE
               plugin_manager.execute_plugins
           #PIPE!
               piped_cmd = plugin_manager.pipe!
               #assert_equal(piped_cmd,str_cmd)
           ##STATS
           #Make working directory and subdirectories
               [OUTPUT_PATH,File.join(OUTPUT_PATH,'plugins_logs')].map{ |d| Dir.mkdir(d) if !Dir.exist?(d) }
           #Execute piped_cmd
               system(piped_cmd)
           #Extract stats!
               stats = {}
               plugin_manager.extract_stats(stats)
           #clean
               plugin_manager.clean_garbage!
           #CLEAN UP
               clean_up

      end

end