########################################################
# Defines the main methods that are necessary to split Nextera long mate pair reads
########################################################

class PluginMatePairs < Plugin

  #Returns an array with the errors due to parameters are missing 
	def check_params
	  	#Priority, base ram
		cores = [1]
		priority = 1
		ram = [50] #mb
	   #Array to store errors 
		errors=[]  
	   #Check params (errors,param_name,param_class,default_value,comment)
		linker_literal_seq = 'CTGTCTCTTATACACATCTAGATGTGTATAAGAGACAG'  
		@params.check_param(errors,'linker_literal_seq','String',linker_literal_seq,'Literal sequence of linker to use in masking')
	   #Check linker seq
		if @params.get_param('linker_literal_seq') != linker_literal_seq
			cores << 1  
			ram << 50
			@linker = @params.get_param('linker_literal_seq')                
		end       
	   #Set resources
		@params.resource('set_requirements',{ 'plugin' => 'PluginMatePairs','opts' => {'cores' => cores,'priority' => priority,'ram'=>ram}})			 
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
		#Nextera LMP splitting
		#Splitnextera call
		module_options['outu'] = 'stdout.fastq'
		module_options['stats'] = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"LMP_splitting_stats.txt")
		module_options['redirection'] = ["2>",File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"LMP_splitting_stats_cmd.txt")]
		module_options['trimq'] = @params.get_param('quality_threshold')
		module_options['booleans'] = booleans if !booleans.empty?
		#IF @linker is defined
		if defined?(@linker)
			#Mask module
			mask_module = {}
			mask_module['kmask'] = 'J'
			mask_module['k'] = 19
			mask_module['mink'] = 11
			mask_module['hdist'] = 1
			mask_module['hdist2'] = 0
			mask_module['literal'] = @linker
			mask_module['redirection'] = ["2>",File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"LMP_mask_cmd.txt")]                  
			#Add to hash
			opts << mask_module
		else
			module_options['mask'] = 't'
		end
		#Return
		opts << module_options
		return opts
	end
 #Get cmd
	def get_cmd(result_hash)		   
		#Empty cmd array
		cmd = []
		#IF, mask cmd
		cmd << @bbtools.load_bbduk(result_hash['opts'].first) if defined?(@linker)
		#Nextera cmd
		cmd << @bbtools.load_splitnextera(result_hash['opts'].last)
		#Return  
		return cmd.join(' | ')
	end
 #Get stats
	def get_stats(stats_files,stats)
		stats["plugin_mate_pairs"] = {} if !stats.key?('plugin_mate_pairs')
		stats["plugin_mate_pairs"]["long_mate_pairs"] = {} if !stats['plugin_mate_pairs'].key?('long_mate_pairs')
		stats["plugin_mate_pairs"]["long_mate_pairs"]["count"] = 0 if !stats['plugin_mate_pairs']['long_mate_pairs'].key?('count')
		# Extracting stats     
		regexp_str = "^(Long|Unknown|Adapters)"
		lines = super(regexp_str,stats_files['stats'].first)
		lmp_reads_lines = [lines.select { |line| (line =~ /^Long/) }.first,lines.select { |line| (line =~ /^Unknown/) }.first]             
		['known','unknown'].each_with_index { |tag,i| stats['plugin_mate_pairs']['long_mate_pairs'][tag] = lmp_reads_lines[i].split(/\t/)[1].split(" ").first.to_i }
		stats["plugin_mate_pairs"]["long_mate_pairs"]["count"] = ['known','unknown'].map{ |tag| stats['plugin_mate_pairs']['long_mate_pairs'][tag] }.inject(:+)
		stats["plugin_mate_pairs"]["linkers_detected"]= lines.select { |line| (line =~ /^Adapters/) }.first.split(/\t/)[1]
	end
 #Get report!
	def get_report(json,data)
		super
		without = json['sequences']['input_count'] - json['plugin_mate_pairs']['long_mate_pairs']['count']
		with_known = json['plugin_mate_pairs']['long_mate_pairs']['known']
		with_unknown = json['plugin_mate_pairs']['long_mate_pairs']['unknown']
		data['plugin_mate_pairs_percent'] = [
			['content','count'],
			['Non mate pairs',without],
			['unknown',with_unknown],
			['Mate pairs',with_known]
		]         
		@plugin << %(           <div style="overflow: hidden">)
		@plugin << %(             <%=pie(id:'plugin_mate_pairs_percent', header: true, row_names: true, title:"Mate pair reads", responsive: false, config: { 'pieSegmentPrecision' => 2 })%>)
		@plugin << %(             <p style="text-align: center;">Number of linkers_detected: <b style="font-size: large;">#{json['plugin_mate_pairs']['linkers_detected']}</b></p>)
		@plugin << %(           </div>)
		return @plugin
	end 

end