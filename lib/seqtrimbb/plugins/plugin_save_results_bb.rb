########################################################
# Defines the main methods that are necessary to save results
########################################################

class PluginSaveResultsBb < Plugin
  
  #Returns an array with the errors due to parameters are missing 
	def check_params
		#Priority, base ram
		cores = [1]
		priority = 0
		ram = [50] #mb
		#Array to store errors    
		errors=[]
		#Check params (errors,param_name,param_class,default_value,comment)
		@params.check_param(errors,'minlength','String',50,'Minimal reads length to be keep')
		@params.check_param(errors,'ext_cmd','String',nil,'External cmd to pipe')           
		#Set resources
		@params.resource('set_requirements',{ 'plugin' => 'PluginSaveResultsBb','opts' => {'cores' => cores,'priority' => priority,'ram'=>ram}})
		return errors
	end
  #Gets options
	def get_options
		#Opts Array
		opts = Array.new
		#Module options Hash
		module_options = {}
		# Adding input info, vital for a output of paired samples
		module_options.merge!(get_output)    
		# Adding plugins options for reformar module
		module_options['minlength'] = @params.get_param('minlength')
		# Adding commandline redirection
		module_options['redirection'] = ["2>",File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"output_stats.txt")]
		#Add hash to array and return
		opts << module_options
		return opts
	end
  #Get cmd
	def get_cmd(result_hash)
		#Return  
		return @bbtools.load_reformat(result_hash['opts'].first)
	end
  #Get stats
	def get_stats(stats_files,stats)
		stats["sequences"] = {} if !stats.key?("sequences")
		#Extract stats
		regexp = "^(Output:|Result:|Short)"
		lines = super(regexp,stats_files['cmd'].first)
		output = lines.select { |line| (line =~ /^(Output:|Result:)/) }
		short_discard = lines.select { |line| line =~ /^Short/ }
		stats["sequences"]["output_count"] = output.first.split(/\t/)[1].split(" ").first.to_i if !output.empty?
		stats["sequences"]["output_count_bases"] = output.first.split(/\t/)[2].split(" ").first.to_i if !output.empty?
		stats["sequences"]["final_short_reads_discards"] = short_discard.first.split(/\t/)[1].split(" ").first.to_i if !short_discard.empty?
	end

end
