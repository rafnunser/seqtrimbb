########################################################
# Defines the main methods that are necessary to execute a plugin
########################################################

class Plugin

	#Loads the plugin's execution
	def initialize(params,stbb_db,bbtools)
			 @params = params
			 @stbb_db = stbb_db
			 @bbtools = bbtools
	end
	#Returns an array with the errors due to parameters are missing
	def check_params
			 return []			 
	end
	#Get options
	def get_options			
			 return []
	end
	#Begins the plugin's execution
	def get_cmd
		return 'CMD to execute external tool'
	end
	#Get input
	def get_input
		module_options = {}
		case @params.get_param('sample_type')
			when 'interleaved'
				module_options["in"] = @params.get_param('file')[0]
				module_options["int"] = "t"
			when 'single-ended'
				module_options["in"] = @params.get_param('file')[0]
				module_options["int"] = "f"
			when 'paired'
				module_options["in"] = @params.get_param('file')[0]
				module_options["in2"] = @params.get_param('file')[1]
				module_options["int"] = "f"
		end   
		#Adding input info, vital for a proper processing of samples in fasta format
		if @params.get_param('file_format') == "fasta"
			if !@params.get_param('qual').empty?
				if @params.get_param('sample_type') == "paired"
									 module_options["qfin"] = @params.get_param('qual')[0]
									 module_options["qfin2"] = @params.get_param('qual')[1]
				else
									 module_options["qfin"] = @params.get_param('qual')[0]
				end
			else
				module_options["q"] = 40
			end
		end
		return module_options
	end
	#Get output
	def get_output
		module_options = {}
		case @params.get_param('sample_type')
			when 'interleaved'
				module_options["out"] = @params.get_param('outputfile')[0] if @params.get_param('ext_cmd').nil?
				module_options["int"] = "t"
			when 'single-ended'
				module_options["out"] = @params.get_param('outputfile')[0] if @params.get_param('ext_cmd').nil?
				module_options["int"] = "f"
			when 'paired'
				module_options["out"] = @params.get_param('outputfile')[0] if @params.get_param('ext_cmd').nil?
				module_options["out2"] = @params.get_param('outputfile')[1] if @params.get_param('ext_cmd').nil?
				module_options["int"] = "t"
		end 
		return module_options
	end
	#Get database filtering module
	def get_filtering_module(db,plugin)		  
		 # Creates a hash to store modules options
		module_options = {}
		booleans = []
		 # Add minratio to modules options
		module_options['minratio'] =  @params.get_param("#{plugin}_minratio")
		 # Path to database
		module_options['path'] = @stbb_db.get_info(db,'index')
		 # Name and path for the statistics to be generated in the decontamination process
		module_options['refstats'] = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{@stbb_db.get_info(db,'name')}_#{plugin}_filtering_stats.txt")
		 # Adding #{plugin} aditional params
		booleans << @params.get_param("#{plugin}_aditional_params") if !@params.get_param("#{plugin}_aditional_params").nil?    
		 # Adding booleans to module_options
		module_options['booleans'] = booleans if !booleans.empty?
		 # Adding commandline redirection
		module_options['redirection'] = ["2>",File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{@stbb_db.get_info(db,'name')}_#{plugin}_filtering_stats_cmd.txt")] 
		 # Change pipe
		module_options['out'] = nil
		module_options['outu'] = 'stdout.fastq'
		 # Return
		return module_options
	end
	#Get database trimming module
	def get_trimming_module(tip,plugin)
		#Module options Hash
		module_options = {}
		#Booleans array}
		booleans = []
		#tip number
		if tip == 'r'
			ntip = 3
		elsif tip == 'l'
			ntip = 5
		end
		extra = "_#{ntip}" if plugin == 'adapters'
		#Plugin trimming params
		#Set references
		module_options['ref'] = @params.get_param("#{plugin}_db").split(/ |,/).map{ |database| @stbb_db.get_info(database,'fastas').join(',') }.join(',')
		#Trimming options
		module_options['k'] = @params.get_param("#{plugin}#{extra}_kmer_size")
		module_options['mink'] = @params.get_param("#{plugin}#{extra}_min_external_kmer_size")
		module_options['hdist'] = @params.get_param("#{plugin}#{extra}_max_mismatches")
		module_options['ktrim'] = tip
		#Name and path for the statistics to be generated in the trimming process
		module_options['stats'] = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{plugin}_#{ntip}_trimming_stats.txt")
		#Adding necessary fragment to save unpaired singles
		module_options['outs'] = File.join(File.expand_path(OUTPUT_PATH),"singles_#{plugin}_#{ntip}_trimming#{@params.get_param('suffix')}") if @params.get_param('save_unpaired')
		#Adding necessary info to process paired samples
		if (@params.get_param('sample_type') == "paired" || @params.get_param('sample_type') == "interleaved") && @params.get_param("#{plugin}_merging_pairs_trimming") == 'true'
			['tbo','tpe'].map { |tag| booleans << tag }
		end                          
		#Adding #{plugin} aditional params
		booleans << @params.get_param("#{plugin}_aditional_params") if !@params.get_param("#{plugin}_aditional_params").nil?
		#Adding booleans to module_options
		module_options['booleans'] = booleans if !booleans.empty?
		#Adding commandline redirection
		module_options['redirection'] = ["2>",File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"#{plugin}_#{ntip}_trimming_stats_cmd.txt")]
		#return
		return module_options
	end
  #Get plugins stats line
	def get_stats(expr,stat_file)
		if !File.exist?(stat_file)
			STDERR.puts "ERROR. Stats file #{stat_file} does no exist. Something went wrong during plugins execution."
			show_execution(stat_file.sub(/.txt$/,'_cmd.txt'))
			exit(-1)
		end
		return extract_lines(expr,stat_file)    		 
	end
  #Execution errors check
	def check_execution_errors(cmds_array)			 
		cmds_array.each do |cmd_file|
			if !File.exist?(cmd_file)
				STDERR.puts "ERROR. Plugin log file #{cmd_file} does no exist. Something went wrong during plugins execution."
				exit(-1)
			end
			lines = extract_lines(%q(.*(Exception in thread|Error(?!.*Rate.*)|ERROR|error(?!-free.*)).*),cmd_file)
			if !lines.empty?
				STDERR.puts "Internal error in BBtools execution."
				show_execution(cmd_file)
				exit(-1)
			end
		end
	end
  #Show execution
  	def show_execution(cmd_file)
		plugin = cmd_file.match(/^.*(plugin.*)_stats.*/).captures.first.sub(/_/,"\s").upcase
		if File.exist?(cmd_file)
			STDERR.puts "#{plugin} execution LOG:"
			STDERR.puts "-----------------------------------------------------------------------"
			STDERR.puts extract_lines('',cmd_file).join("\n")
		else
			STDERR.puts "ERROR. File #{cmd_file} not found. Is not possible to show #{plugin} execution"
		end
  	end
  #Extract lines from files
  	def extract_lines(expr,file)
		lines_to_return = []
		open_file = File.open(file)
		open_file.each do |line|
			line.chomp!
			if !line.empty? && (line =~ /#{expr}/)
				lines_to_return << line
			end
		end
		open_file.close 
		return lines_to_return
  	end
  #Clean up operations
	def clean_up

	end
 #Get report!
	def get_report(json,data)
		@plugin = []
		@plugin << %(           <h3 style="text-align:center;">#{self.class}</h3>)
		return @plugin
	end

end
