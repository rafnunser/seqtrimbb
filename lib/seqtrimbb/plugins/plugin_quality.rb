########################################################
# Defines the main methods that are necessary to trim bad quality
########################################################

class PluginQuality < Plugin

  #Returns an array with the errors due to parameters are missing 
	def check_params
	   #Priority, base ram
		cores = [1]
		priority = 1
		ram = [50] #mb
	   #Array to store errors 
		errors=[]  
	   #Check params (errors,param_name,param_class,default_value,comment)
		@params.check_param(errors,'quality_threshold','String',20,'Quality threshold to be applied (Phred quality score)')
		@params.check_param(errors,'quality_trimming_position','String','both','Trim bad quality bases in which position: right, left or both (default)' )
		@params.check_param(errors,'quality_aditional_params','String',nil,'Aditional BBduk2 parameters for quality trimming, add them together between quotation marks and separated by one space')
	   #Set resources
		@params.resource('set_requirements',{ 'plugin' => 'PluginQuality','opts' => {'cores' => cores,'priority' => priority,'ram'=>ram}})			 
		return errors			 
	end
  #Get options  
	def get_options
		#Opts Array
		opts = Array.new
		#Module options Hash
		module_options = {}
		#Booleans array}
		booleans = []    
		#Quality's trimming params
		module_options['trimq'] = @params.get_param('quality_threshold')
		#Adding necessary fragment to save unpaired singles
		if @params.get_param('save_unpaired')
			module_options['outs'] = File.join(File.expand_path(OUTPUT_PATH),"singles_quality_trimming#{@params.get_param('suffix')}")
		end
		#Choosing which tips are going to be trimmed
		case @params.get_param('quality_trimming_position')
			when 'both'
				module_options['qtrim'] = 'rl'
			when 'right'
				module_options['qtrim'] = 'r'
			when 'left'
				module_options['qtrim'] = 'l'
		end
		# Adding quality aditional params
		booleans << @params.get_param('quality_aditional_params') if !@params.get_param('quality_aditional_params').nil?
		# Adding booleans to module_options
		module_options['booleans'] = booleans if !booleans.empty?
		# Adding commandline redirection
		module_options['redirection'] = ["2>",File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"quality_trimming_stats.txt")]
		#Add hash to array and return
		opts << module_options
		return opts
	end
 #Get cmd
	def get_cmd(result_hash)	   
		#Return  
		return @bbtools.load_bbduk(result_hash['opts'][0])
	end
#Get stats
	def get_stats(stats_files,stats)
		stats["plugin_quality"] = {} if !stats.key?("plugin_quality")
		# Extracting stats
		regexp = "^QTrimmed:" 
		lines = super(regexp,stats_files['cmd'].first)
		splitted_line = lines[0].split(/\t/)
		stats["plugin_quality"]["quality_trimmed_reads"] = splitted_line[1].split(" ")[0].to_i
		stats["plugin_quality"]["quality_trimmed_bases"] = splitted_line[2].split(" ")[0].to_i             

	end
 #Get report!
	def get_report(json,data)
		super
		with = json['plugin_quality']['quality_trimmed_reads']          
		without = json['sequences']['input_count'] - with
		data['plugin_quality_percent'] = [
			['content','count'],
			['non quality trimmed reads',without],
			['quality trimmed reads',with]
		]

		with_bases = json['plugin_quality']['quality_trimmed_bases']
		without_bases = json['sequences']['input_count_bases'] - with_bases

		data['plugin_quality_percent_bases'] = [
			['content','count'],
			['non quality trimmed bases',without_bases],
			['quality trimmed bases',with_bases]
		]           

		@plugin << %(           <div style="overflow: hidden" class="flex-row">)
		@plugin << %(             <div class="flex-canvas-50">)
		@plugin << %(               <%=pie(id:'plugin_quality_percent', header: true, row_names: true, title:"Quality trimmed reads", config: { 'pieSegmentPrecision' => 2 })%>)
		@plugin << %(             </div>)
		@plugin << %(             <div class="flex-canvas-50">)
		@plugin << %(               <%=pie(id:'plugin_quality_percent_bases', header: true, row_names: true, title:"Quality trimmed bases", config: { 'pieSegmentPrecision' => 2 })%>)
		@plugin << %(             </div>)
		@plugin << %(           </div>)
		return @plugin
	end

end
