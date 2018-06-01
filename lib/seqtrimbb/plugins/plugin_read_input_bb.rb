########################################################
# Defines the main methods that are necessary to read input
########################################################

class PluginReadInputBb < Plugin

  #Returns an array with the errors due to parameters are missing 
	def check_params
		#Priority, base ram
		cores =[1]
		priority = 0
		ram = [50] #mb
		#Array to store errors    
		errors=[]  
		#Set resources
		@params.resource('set_requirements',{ 'plugin' => 'PluginReadInputBb','opts' => {'cores' => cores,'priority' => priority,'ram'=>ram}})  
		return errors
	end  
  #Get options
	def get_options
		#Opts Array
		opts = Array.new
		#Module options Hash
		module_options = {}
		#Adding input info, for a proper processing of paired samples
		module_options.merge!(get_input)
		# Adding commandline redirection
		module_options['redirection'] = ["2>",File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"input_stats.txt")]    
		#Add hash to array and return
		opts << module_options
		return opts
	end
  #Get cmd
	def get_cmd(result_hash)
		#Return  
		return @bbtools.load_reformat(result_hash['opts'].first)
	end
  #Get stats!
	def get_stats(stats_files,stats)
		#Number of input reads!
		stats["sequences"] = {} if !stats.key?("sequences")
		#Call to super with regexp
		regexp_str = "^(Input:|Reads Used:)"
		lines = super(regexp_str,stats_files['cmd'].first)
		#Set input reads
		stats["sequences"]["input_count"] = lines[0].split(/\t/)[1].split(" ")[0].to_i
		stats["sequences"]["input_count_bases"] = lines[0].split(/\t/)[2].split(" ")[0].to_i
	end

end
