########################################################
# Defines the main methods that are necessary to trim adapters
########################################################

class PluginAdapters < Plugin

  #Returns an array with the errors due to parameters are missing 
	def check_params	   
	   #Priority, base ram
		cores = [1]
		priority = 1
		ram = [100] #mb
	   #Array to store errors 
		errors=[]  
	   #Check params (errors,param_name,param_class,default_value,comment)
		@params.check_param(errors,'adapters_trimming_position','String','both','Trim adapters in which position: right, left or both (default)')
		#if plugins trims reads in both tips, double the requirements
		if @params.get_param('adapters_trimming_position') == 'both'
			cores << 1
			ram << 100
		end 
		@params.check_param(errors,'adapters_db','DB','adapters','Sequences of adapters to use in trimming',@stbb_db)
		ram.map!{ |iram| iram * @params.get_param('adapters_db').split(/ |,/).count }			 
		@params.check_param(errors,'adapters_3_kmer_size','Integer',15,'Main kmer size to use in adapters trimming. Right tip.')
		@params.check_param(errors,'adapters_5_kmer_size','Integer',@params.get_param('adapters_3_kmer_size').to_i + 6,'Main kmer size to use in adapters trimming. Left tip.')
		@params.check_param(errors,'adapters_3_min_external_kmer_size','Integer',8,'Minimal kmer size to use in read tips during adapters trimming. Right tip.')
		@params.check_param(errors,'adapters_5_min_external_kmer_size','Integer',@params.get_param('adapters_3_min_external_kmer_size').to_i + 3,'Minimal kmer size to use in read tips during adapters trimming. Left tip.')    
		@params.check_param(errors,'adapters_3_max_mismatches','Integer',1,'Max number of mismatches accepted during adapters trimming. Right tip.')
		@params.check_param(errors,'adapters_5_max_mismatches','Integer',@params.get_param('adapters_3_max_mismatches').to_i,'Max number of mismatches accepted during adapters trimming. Left tip.')
		@params.check_param(errors,'adapters_aditional_params','String',nil,'Aditional BBduk parameters, add them together between quotation marks and separated by one space')
		@params.check_param(errors,'adapters_merging_pairs_trimming','String','true','Trim adapters of paired reads using mergind reads methods')
	   #Set resources
		@params.resource('set_requirements',{ 'plugin' => 'PluginAdapters','opts' => {'cores' => cores,'priority' => priority,'ram'=>ram}})
		return errors
	end
  #Get options
	def get_options
		#Opts Array
		opts = Array.new
		# Choosing which tips are going to be trimmed
		case @params.get_param('adapters_trimming_position')
			when 'both'
				['r','l'].map { |tip| opts << get_trimming_module(tip,'adapters') }
			when 'right'
				opts << get_trimming_module('r','adapters')
			when 'left'
				opts << get_trimming_module('l','adapters')
		end 
		return opts
	end

 #Get cmd
	def get_cmd(result_hash)		   
		#Return  
		return result_hash['opts'].map { |opt| @bbtools.load_bbduk(opt) }.join(' | ')
	end
 #Get stats
	def get_stats(stats_files,stats)
		stats["plugin_adapters"] = {} if !stats.key?('plugin_adapters')
		stats["plugin_adapters"]["sequences_with_adapter"] = {} if !stats['plugin_adapters'].key?('sequences_with_adapter')
		stats["plugin_adapters"]["adapter_id"] = {} if !stats['plugin_adapters'].key?('adapter_id')
		stats["plugin_adapters"]["sequences_with_adapter"]["count"] ||= 0
		stats["plugin_adapters"]["adapter_type"] = {} if !stats['plugin_adapters'].key?('adapter_type') 
		#Extracting stats 
		trimming_stats_files = stats_files['stats'].select { |file| (File.basename(file,'.txt') =~ /\S*trimming\S*/) }
		trimming_stats_files.each do |file|
			lines = super('',file)
			tip = File.basename(file,'.txt').split("_")[1]
			header_matched = lines.select { |line| (line =~ /^\s*#Matched/) }
			ids = lines.select { |line| (line =~ /^(?!\s*#).+/) }
			stats["plugin_adapters"]["sequences_with_adapter"]["count"] += header_matched.first.split(/\t/)[1].to_i if !header_matched.empty?         
			stats["plugin_adapters"]["adapter_type"][tip.to_s] ||= 0
			stats["plugin_adapters"]["adapter_type"][tip.to_s] += header_matched.first.split(/\t/)[1].to_i if !header_matched.empty? 
			ids.each { |line| stats["plugin_adapters"]["adapter_id"][line.split(/\t/)[0]] ||= 0 }                     
			ids.each { |line| stats["plugin_adapters"]["adapter_id"][line.split(/\t/)[0]] += line.split(/\t/)[1].to_i }
		end
	end
 #Get report!
	def get_report(json,data)
		super
		without_adapter = json['sequences']['input_count'] - json['plugin_adapters']['sequences_with_adapter']['count']
		with_3 = json['plugin_adapters']['adapter_type']['3']
		with_5 = json['plugin_adapters']['adapter_type']['5']
		  # data['plugin_adapters_percent'] = [
		  #   ['content','without adapter','with adapter at 3-end','with adapter at 5-end'],
		  #   ['count',without_adapter,with_3,with_5]
		  # ]
		data['plugin_adapters_percent'] = [
			['content','count'],
			['without adapter',without_adapter],
			['with adapter at 3-end',with_3],
			['with adapter at 5-end',with_5]
		  ]          
		data['plugin_adapters_ids'] = []
		data['plugin_adapters_ids'] << json['plugin_adapters']['adapter_id'].keys
		data['plugin_adapters_ids'] << json['plugin_adapters']['adapter_id'].values
		  # data['plugin_adapters'][1][1].each do |key,value|
		  #   data['plugin_adapters_ids'] << ['count',value]
		  # end

		@plugin << %(           <div style="overflow: hidden" class="flex-row">)
		@plugin << %(             <div class="flex-canvas-50">)
		@plugin << %(               <%=pie(id:'plugin_adapters_percent', header: true, row_names: true, title:"Adapters presence", config: { 'pieSegmentPrecision' => 2 })%>)
		@plugin << %(             </div>)
		@plugin << %(             <div class="flex-canvas-50">)
		@plugin << %(               <%=barplot(id:'plugin_adapters_ids', header: true, title:"Adapters trimmed from the reads", x_label: 'Trimmed N times', config: { 'showLegend' => false })%>)
		@plugin << %(             </div>)
		@plugin << %(           </div>)
		return @plugin
	end

end
