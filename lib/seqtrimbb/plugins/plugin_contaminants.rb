########################################################
# Defines the main methods that are necessary to decontaminate reads
########################################################

class PluginContaminants < Plugin

  #Returns an array with the errors due to parameters are missing 
	def check_params
		#Priority, base ram
		cores = []
		priority = 2
		ram = []
		base_ram = 720 #mb
		#Array to store errors        
		errors=[]  
	   #Check params (errors,param_name,param_class,default_value,comment)             
		@params.check_param(errors,'contaminants_db','DB','contaminants','Databases to use in decontamination: internal name or full path to fasta file or full path to a folder containing an external database in fasta format',@stbb_db)
		@params.check_param(errors,'contaminants_minratio','String','0.56','Minimal ratio of contaminants kmers in a read to be deleted')
		@params.check_param(errors,'contaminants_decontamination_mode','String','regular','Decontamination mode: regular to just delete contaminated reads, or excluding to avoid deleting reads using contaminant species similar (genus or species) to the samples species, use excluding genus for a conservative approach or excluding species for maximal sensibility.')
		@params.check_param(errors,'sample_species','String',nil,'Species of the sample to process')	
		@params.check_param(errors,'contaminants_aditional_params','String',nil,'Aditional BBsplit parameters, add them together between quotation marks and separated by one space')
		#Set resources
		if errors.empty?
			#Adds 1 core for each database
			@params.get_param('contaminants_db').split(/ |,/).each do |database|
				cores << 1
				ram << (@stbb_db.get_info(database,'index_size')/2.0**20).round(0) + base_ram 
			end
			@params.resource('set_requirements',{ 'plugin' => 'PluginContaminants','opts' => {'cores' => cores,'priority' => priority,'ram'=>ram}})
		end
		return errors    
	end
  #Get options
	def get_options
		#Creates an array to store individual options for every database in contaminants_dbs
		opts = Array.new
		#Iteration to assemble individual options
		@params.get_param('contaminants_db').split(/ |,/).each do |db|
			# DECONTAMINATION MODE selection:
			# Excluding decontamination mode
			if @params.get_param('contaminants_decontamination_mode').downcase.split(" ")[0] == 'exclude'
				# Sample species check
				if [nil,'',' '].include?(@params.get_param('sample_species'))
					STDERR.puts "PluginContaminants: Sample species param is empty and decontamination mode is #{@params.get_param('contaminants_decontamination_mode')}. Specify #{@params.get_param('contaminants_decontamination_mode').downcase.split(" ")[1]}, or change decontamination_mode to regular"
					exit(-1)
				end
				# Creates an array to store the paths to selected fastas. Test contaminants in database for compatibility with the sample's species or samples's genus, then add the proper contaminants 
				db_refs = []                             
				@stbb_db.get_info(db,'list').each_with_index { |contaminant,i| db_refs << @stbb_db.get_info(db,'fastas',i) if (contaminant.split(" ").first != @params.get_param('sample_species').split(" ").first && @params.get_param('contaminants_decontamination_mode').downcase.split(" ")[1] == 'genus') || (contaminant != @params.get_param('sample_species') && @params.get_param('contaminants_decontamination_mode').downcase.split(" ")[1] == 'species') }
				# Set an external database to create an index
				break if db_refs.empty?
				db = @stbb_db.set_excluding(db_refs)
			end 
			#Add options to opts array
			opts << get_filtering_module(db,'contaminants')             
		end
		#Return
		return opts
	end 
  #Get cmd
	def get_cmd(result_hash)			
		#Load all databases cmds
		full_cmd = Array.new
		result_hash['opts'].each do |opt_hash|
			full_cmd << @bbtools.load_bbsplit(opt_hash)    
		end
		#Return
		return full_cmd.join(' | ')
	end
  #Get stats
	def get_stats(stats_files,stats)
		#Contaminands hash
		stats["plugin_contaminants"] = {} if !stats.key?("plugin_contaminants")
		stats["plugin_contaminants"]["contaminated_sequences_count"] = 0 if !stats['plugin_contaminants'].key?("contaminated_sequences_count")
		stats["plugin_contaminants"]["contaminants_ids"] = {} if !stats['plugin_contaminants'].key?("contaminants_ids")
		#Regexp
		regexp_str = "^(?!\s*#).+"
		#For every database refstats
		stats_files['stats'].each do |refstats_file|
			lines = super(regexp_str,refstats_file)
			lines.each do |line|
				splitted_line = line.split(/\t/)
				nreads = splitted_line[5].to_i + splitted_line[6].to_i
				stats["plugin_contaminants"]["contaminants_ids"][splitted_line[0]] = nreads
				stats["plugin_contaminants"]["contaminated_sequences_count"] += nreads
			end
		end
	end

 #Get report!
	def get_report(json,data)
		super
		with = json['plugin_contaminants']['contaminated_sequences_count']          
		without = json['sequences']['input_count'] - with

		data['plugin_contaminants_percent'] = [
			['content','count'],
			['non contaminant reads',without],
			['contaminant reads',with]
		]          
		data['plugin_contaminants_ids'] = []
		data['plugin_contaminants_ids'] << json['plugin_contaminants']['contaminants_ids'].keys
		data['plugin_contaminants_ids'] << json['plugin_contaminants']['contaminants_ids'].values

		@plugin << %(           <div style="overflow: hidden" class="flex-row">)
		@plugin << %(             <div class="flex-canvas-50">)
		@plugin << %(              <%=pie(id:'plugin_contaminants_percent', header: true, row_names: true, title:"Contaminant reads presence", config: { 'pieSegmentPrecision' => 2 })%>)
		@plugin << %(             </div>)
		@plugin << %(             <div class="flex-canvas-50">)
		@plugin << %(              <%=barplot(id:'plugin_contaminants_ids', header: true, title:"Contaminant reads", x_label: 'Nreads', config: { 'showLegend' => false })%>)
		@plugin << %(             </div>)
		@plugin << %(           </div>)
		return @plugin
	end

end
