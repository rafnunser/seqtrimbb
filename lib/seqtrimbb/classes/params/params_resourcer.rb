#########################################
# This class provided the methods to properly distribute given resources between plugins
#########################################

class ParamsResourcer < Params
	  
	def initialize
		#Init hashes
		@plugin_cores = {}
		@plugin_priority = {}
		@plugin_ram = {}
		#Load cores
		@cores = get_param('workers').to_i 
	end

	def set_requirements(opt_hash)
		#Add plugins requirements 
		@plugin_cores[opt_hash['plugin']] = opt_hash['opts']['cores']
		@plugin_priority[opt_hash['plugin']] = opt_hash['opts']['priority']
		@plugin_ram[opt_hash['plugin']] = opt_hash['opts']['ram']
	end

	def distribute_resources(opt_hash)			 
		final_plugin_list = opt_hash['list']
		result_hash = opt_hash['result']
		#Distribute resources 
		distribute_cores(final_plugin_list)
		distribute_ram(final_plugin_list)
		#Assign to options
		final_plugin_list.each do |plugin|
			@plugin_cores[plugin].each_with_index do |cores,i|
				result_hash[plugin]['opts'][i]['cores'] = cores
			end
			@plugin_ram[plugin].each_with_index do |ram,i|
				result_hash[plugin]['opts'][i]['ram'] = "#{ram}m"
			end
		end
	end 

	def distribute_cores(final_plugin_list)
		#Full throttle (all plugins)
		if get_param('full_throttle')
			final_plugin_list.each do |plugin|
				@plugin_cores[plugin].map! { |value| @cores }
			end
			#return
			return
		end
		#Prepare Distribution
		max_priority = @plugin_priority.slice(*final_plugin_list).values.max
		distribute_list = final_plugin_list.select { |key| @plugin_priority[key] == max_priority }
		surplus_cores = @cores - ( final_plugin_list.map { |plugin| @plugin_cores[plugin].count }.inject(:+) )
		#Return
		return if (surplus_cores <= 0 || distribute_list.empty?)
		#Distribute!
		while surplus_cores > 0
			distribute_list.each do |plugin|
				@plugin_cores[plugin].each_with_index do |value,i|
					@plugin_cores[plugin][i] += 1
					surplus_cores -= 1
					break if surplus_cores == 0
				end
					break if surplus_cores == 0
			end
		end
	end

	def distribute_ram(final_plugin_list)
		bbmap_based = %w(plugin_contaminants plugin_user_filter plugin_vectors)
		#Adds RAM for extra thread
		final_plugin_list.each do |plugin|
			@plugin_ram[plugin].each_with_index do |ram,i|
				@plugin_ram[plugin][i] = ram + 70*(@plugin_cores[plugin][i] - 1) if bbmap_based.include?(plugin)
				@plugin_ram[plugin][i] = ram + 10*(@plugin_cores[plugin][i] - 1) if !bbmap_based.include?(plugin)
			end
		end
	end

end