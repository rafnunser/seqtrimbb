######################################
# Test Options Parser and Params class
######################################
require 'test_helper'

class OptionsParamsTest < Minitest::Test
  
   #Test options parser class
	     def test_options
   
	     ##TODO - Test exits
	           #Workers
               args = ['-w','4']
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:workers],4)
             #File
               args = ["-Q", File.join(ROOT_PATH,"files","testfiles","testfile_single.fastq.gz")]               
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:file],[File.join(ROOT_PATH,"files","testfiles","testfile_single.fastq.gz")])
               args = ["-Q", "#{File.join(ROOT_PATH,"files","testfiles","testfile_1.fastq.gz")},#{File.join(ROOT_PATH,"files","testfiles","testfile_2.fastq.gz")}"]               
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:file].count,2)
             #Qual
               args = ["-Q", File.join(ROOT_PATH,"files","testfiles","testfile_single.fastq.gz"),"-q",File.join(ROOT_PATH,"files","testfiles","qualfile_1.qual.gz")]               
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:qual],[File.join(ROOT_PATH,"files","testfiles","qualfile_1.qual.gz")])
               args = ['-q',"#{File.join(ROOT_PATH,"files","testfiles","qualfile_1.qual.gz")},#{File.join(ROOT_PATH,"files","testfiles","qualfile_2.qual.gz")}"]               
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:qual].count,2)
             #Template
               args = ["-t","#{File.join(ROOT_PATH,"files","faketemplate.txt")}"]               
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:template],File.join(ROOT_PATH,"files","faketemplate.txt"))
             #Output
               args = ['-O', OUTPUT_PATH]               
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:final_output_path],OUTPUT_PATH)
             #Gzip
               args = ['-z']
               options = OptionsParserSTBB.parse(args)
               assert(!options[:write_in_gzip])
             #Force execution
               args = ['-F']
               options = OptionsParserSTBB.parse(args)
               assert(options[:force_execution])
             #Generate stats
               args = ['-G']
               options = OptionsParserSTBB.parse(args)
               assert(options[:generate_initial_stats])
               assert(options[:generate_final_stats])
               args = ['-G','initial']
               options = OptionsParserSTBB.parse(args)
               assert(options[:generate_initial_stats])
               args = ['-G','final']
               options = OptionsParserSTBB.parse(args)
               assert(options[:generate_final_stats])
             #Install
               args = ['-i']
               options = OptionsParserSTBB.parse(args)
               assert(options[:install_db])
               args = ['-i','test']
               options = OptionsParserSTBB.parse(args)
               assert(options[:install_db])
               assert_equal(options[:install_db_name],['test'])
             #Check
               args = ['-c']
               options = OptionsParserSTBB.parse(args)
               assert(!options[:install_db])
             #List
               args = ['-L']
               options = OptionsParserSTBB.parse(args)
               assert(options[:list_db])
               args = ['-L','test']
               options = OptionsParserSTBB.parse(args)
               assert(options[:list_db])
               assert_equal(options[:list_db_name],['test'])
	           #Databases action
	             args = ['--databases_action']
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:databases_action],'replace')
	             args = ['--databases_action', "add"]
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:databases_action],'add')                             
	           #Databases action list
	             args = ['--databases_list']
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:databases_list],[])
	             args = ['--databases_list','test']
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:databases_list],['test'])  
             #Overwrite
	             args = ['--overwrite_params',"PARAMS;PARAMS2"]
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:overwrite_params],"PARAMS;PARAMS2")             
             #External cmd
	             args = ['--external_cmd',"PARAMS;PARAMS2"]
               options = OptionsParserSTBB.parse(args)
               assert_equal(options[:ext_cmd],"PARAMS;PARAMS2")   

	     end
	 #Test params loader class
	     def test_params
	            
	           #Load options
	             args = ['-Q',File.join(ROOT_PATH,"files","testfiles","testfile_single.fastq.gz"),'-t',File.join(SEQTRIM_PATH,'templates','genomics.txt') ]
               options = OptionsParserSTBB.parse(args)
             #Load Databases
               setup_databases
               bbtools = BBtools.new(BBPATH)
             #Init and load params
               params = Params.new(options,bbtools)
             #Test template read
               assert_equal('PluginAdapters,PluginContaminants,PluginQuality,PluginLowComplexity',params.get_param('plugin_list'))
             #Test options load
               options.keys.each do |param|
                       assert_equal(options[param],params.get_param(param.to_s)) if !options[param].nil?
                       assert_nil(params.get_param(param.to_s)) if options[param].nil?
               end
             #Test params processing
               assert_equal('.fastq.gz',params.get_param('suffix'))
               #Overwrite params
	             args = ['-Q',File.join(ROOT_PATH,"files","testfiles","testfile_single.fastq.gz"),'-t',File.join(SEQTRIM_PATH,'templates','genomics.txt'),'--overwrite_params',"PARAM1=VALUE1;PARAM2=VALUE2"]
               options = OptionsParserSTBB.parse(args)
               params = Params.new(options,bbtools)
               assert_equal('VALUE1',params.get_param('PARAM1'))
               assert_equal('VALUE2',params.get_param('PARAM2'))
               #Single-ended file
               assert_equal('fastq',params.get_param('file_format'))
               assert_equal('sanger',params.get_param('qual_format'))
               assert_equal('single-ended',params.get_param('sample_type'))
               assert_equal('f',params.get_param('default_options')['int'])
               assert_equal([File.join(File.expand_path(OUTPUT_PATH),"sequences_#{params.get_param('suffix')}")],params.get_param('outputfile'))
               #Interleaved file
	             args = ['-Q',File.join(ROOT_PATH,"files","testfiles","testfile_interleaved.fastq.gz"),'-t',File.join(SEQTRIM_PATH,'templates','genomics.txt')]
               options = OptionsParserSTBB.parse(args)
               params = Params.new(options,bbtools)               
               assert_equal('interleaved',params.get_param('sample_type'))
               assert_equal('t',params.get_param('default_options')['int'])
               assert_equal([File.join(File.expand_path(OUTPUT_PATH),"interleaved#{params.get_param('suffix')}")],params.get_param('outputfile'))               
               #Fasta / Paired
	             args = ['-Q',"#{File.join(ROOT_PATH,"files","testfiles","testfile_1.fasta.gz")},#{File.join(ROOT_PATH,"files","testfiles","testfile_1.fasta.gz")}",'-t',File.join(SEQTRIM_PATH,'templates','genomics.txt')]
               options = OptionsParserSTBB.parse(args)
               params = Params.new(options,bbtools)  
               assert_equal('paired',params.get_param('sample_type'))
               assert_equal('t',params.get_param('default_options')['int'])
               assert_equal([File.join(File.expand_path(OUTPUT_PATH),"paired_1#{params.get_param('suffix')}"),File.join(File.expand_path(OUTPUT_PATH),"paired_2#{params.get_param('suffix')}")],params.get_param('outputfile'))               
               #Fasta with qual	             
	             args = ['-Q',"#{File.join(ROOT_PATH,"files","testfiles","testfile_1.fasta.gz")},#{File.join(ROOT_PATH,"files","testfiles","testfile_1.fasta.gz")}",'-q',"#{File.join(ROOT_PATH,"files","testfiles","qualfile_1.qual.gz")},#{File.join(ROOT_PATH,"files","testfiles","qualfile_1.qual.gz")}",'-t',File.join(SEQTRIM_PATH,'templates','genomics.txt')]
               options = OptionsParserSTBB.parse(args)
               params = Params.new(options,bbtools)  
               assert_equal('paired',params.get_param('sample_type'))
               assert_equal('t',params.get_param('default_options')['int'])
               assert_equal([File.join(File.expand_path(OUTPUT_PATH),"paired_1#{params.get_param('suffix')}"),File.join(File.expand_path(OUTPUT_PATH),"paired_2#{params.get_param('suffix')}")],params.get_param('outputfile'))
             #Test Check plugin list params
               pl_error = []
               params.check_param(pl_error,'plugin_list','PluginList',nil,'Plugins applied to every sequence, separated by commas. Order is important')
               assert_equal(params.get_param('plugin_list').split(','),['PluginReadInputBb'] + 'PluginAdapters,PluginContaminants,PluginQuality,PluginLowComplexity'.strip.split(',').map!{|e| e.strip}.reject{|p| ['PluginReadInputBb','PluginSaveResultsBb'].include?(p)} + ['PluginSaveResultsBb'])
               params.set_param('plugin_list','     ')
               params.check_param(pl_error,'plugin_list','PluginList',nil,'Plugins applied to every sequence, separated by commas. Order is important')
               params.set_param('plugin_list','FAKE_PLUGIN')
               params.check_param(pl_error,'plugin_list','PluginList',nil,'Plugins applied to every sequence, separated by commas. Order is important')
               assert_equal(pl_error,["Param plugin_list is not a valid PluginList. Current value is #     #. PluginList is nil or empty","Param plugin_list is not a valid PluginList. Current value is #FAKE_PLUGIN#. Plugin FAKE_PLUGIN does not exists"])             
             #Test Check db params
              ## Initialize databases object
               stbb_db = DatabasesSupportHandler.new({:workers => 1},File.join(OUTPUT_PATH,'DB'),bbtools)
              # Init internal support
               stbb_db.init_internal({:databases_action => 'replace', :databases_list => Array.new})
              # Maintenance (test check)
               stbb_db.maintenance_internal({:check_db => true})
              #Check internal databases
               databases_error = []
               params.check_param(databases_error,'fake_databases','DB','contaminants,vectors','Fake databases',stbb_db)
               params.delete_param('fake_databases')
               params.check_param(databases_error,'fake_databases','DB','fake_db','Fake databases',stbb_db)
               str_db = ['installed','indexed','present on internal databases list'].join(" and/or ")
               assert_equal("Param fake_databases is not a valid DB. Current value is #fake_db#. Database fake_databases is NOT:\n#{str_db}",databases_error[0])
              #Check external databases
               sample_file =stbb_db.info[['adapters','contaminants','contaminants_seqtrim1','cont_bacteria','cont_fungi','cont_mitochondrias','cont_plastids','cont_ribosome','cont_viruses','vectors'].sample]['fastas'].sample
               ext_dbs = [File.join(File.join(OUTPUT_PATH,'DB'),'external_database'),File.join(File.join(OUTPUT_PATH,'DB'),File.basename(sample_file))]
               FileUtils.cp sample_file,File.join(OUTPUT_PATH,'DB')
               Dir.mkdir(ext_dbs[0])
               FileUtils.cp Dir[File.join(File.join(OUTPUT_PATH,'DB'),'fastas',['adapters','contaminants','contaminants_seqtrim1','cont_bacteria','cont_fungi','cont_mitochondrias','cont_plastids','cont_ribosome','cont_viruses','vectors'].sample,"*.fasta*")],ext_dbs[0]
               databases_error = []
               params.delete_param('fake_databases')
               params.check_param(databases_error,'fake_databases','DB',ext_dbs.join(','),'Fake databases',stbb_db)
               params.check_param(databases_error,'fake_databases','DB',ext_dbs.join(','),'Fake databases',stbb_db)
             #Test Check param
               param_errors = []
               params.check_param(param_errors,'workers','Integer',1)
               params.overwrite_param('workers=uno')
               params.check_param(param_errors,'workers','Integer',1)
               assert_equal(["Param workers is not a valid Integer. Current value is #uno#. "],param_errors)               
           #CLEAN UP
               clean_up
                                
	     end

end