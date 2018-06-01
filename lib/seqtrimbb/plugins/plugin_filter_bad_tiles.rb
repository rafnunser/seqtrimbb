########################################################
# Defines the main methods that are necessary to filter out reads from bad tiles
########################################################

class PluginFilterBadTiles < Plugin

  #Returns an array with the errors due to parameters are missing 
	def check_params
	   #Priority, base ram
		cores = [1]
		priority = 1
	   #RAM
		read_file = File.extname(@params.get_param('file').first) == '.gz' ? Zlib::GzipReader.new(open(@params.get_param('file').first)) : File.read(@params.get_param('file').first)
	    @count = (read_file.each_line.count)/(@params.get_param('file_format') == 'fastq' ? 4 : 2)
		if @count <= 1000000
			cram = 10
		elsif @count > 1000000
			cram = (10 * (@count/1000000)).round
		end
		ram = [250 + cram] #mb
	   #Array to store errors 
		errors=[]  
	   #Check params (errors,param_name,param_class,default_value,comment)
		@params.check_param(errors,'tile_xsize','String',500,'Tile size on X axis')
		@params.check_param(errors,'tile_ysize','String',500,'Tile size on Y axis')		
		@params.check_param(errors,'max_reads_by_tile','String',800,'Max number of reads in a tile' )
		@params.check_param(errors,'filter_bad_tiles_aditional_params','String',nil,'Aditional filterbytiles params')
	   #Set resources
		@params.resource('set_requirements',{ 'plugin' => 'PluginFilterBadTiles','opts' => {'cores' => cores,'priority' => priority,'ram'=>ram}})			 
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
		#add input
		module_options.merge!(get_input)
		#Filter params
		module_options['xsize'] = @params.get_param('tile_xsize')
		module_options['ysize'] = @params.get_param('tile_ysize')
		module_options['target'] = @params.get_param('max_reads_by_tile')
		module_options['dump'] = File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"filter_bad_tiles_stats.txt")		
		# Adding quality aditional params
		booleans << @params.get_param('filter_bad_tiles_aditional_params') if !@params.get_param('filter_bad_tiles_aditional_params').nil?
		# Adding booleans to module_options
		module_options['booleans'] = booleans if !booleans.empty?
		# Adding commandline redirection
		module_options['redirection'] = ["2>",File.join(File.expand_path(OUTPUT_PATH),'plugins_logs',"filter_bad_tiles_stats_cmd.txt")]
		#Add hash to array and return
		opts << module_options
		return opts
	end
 #Get cmd
	def get_cmd(result_hash)	   
		#Return  
		return @bbtools.load_filterbytile(result_hash['opts'][0])
	end
#Get stats
	def get_stats(stats_files,stats)
		stats["plugin_filter_bad_tiles"] = {} if !stats.key?("plugin_filter_bad_tiles")			
		#Input stats
		stats["sequences"] = {} if !stats.key?("sequences")		
		stats["sequences"]["input_count"] = @count if !stats['sequences'].key?("input_count")
		stats["sequences"]["input_count_bases"] = (@count*@params.get_param("read_length").to_i) if !stats['sequences'].key?("input_count_bases")
		# Flagged tiles
		regexp = "^Flagged " 
		flag_lines = super(regexp,stats_files['cmd'].first)
		splitted_line = flag_lines.first.split(/\s/)
		stats["plugin_filter_bad_tiles"]["flagged_tiles"] = splitted_line[1].split(" ")[0].to_i		
		# Extracting reads discarded
		regexp = "^Reads Discarded:" 
		reads_lines = super(regexp,stats_files['cmd'].first)
		splitted_line = reads_lines.first.split(/\s/).reject! { |x| x.empty? } 
		stats["plugin_filter_bad_tiles"]["filtered_by_tile_reads"] = splitted_line[2].to_i
	end
 #Get report!
	def get_report(json,data)
		super
		with = json["plugin_filter_bad_tiles"]["filtered_by_tile_reads"]          
		without = json['sequences']['input_count'] - with
		data['plugin_badtiles_percent'] = [
			['content','count'],
			['Good tiles reads',without],
			['Bad tiles reads',with]
		]        

		@plugin << %(           <div style="overflow: hidden" class="flex-row">)
		@plugin << %(             <div class="flex-canvas-50">)
		@plugin << %(               <%=pie(id:'plugin_badtiles_percent', header: true, row_names: true, title:"Reads by tiles", config: { 'pieSegmentPrecision' => 2 })%>)
		@plugin << %(             </div>)
		@plugin << %(             <div class="flex-canvas-50">)
		@plugin << %(           	<p style="text-align: center;">Number of tiles flagged: <b style="font-size: large;">#{json["plugin_filter_bad_tiles"]["flagged_tiles"]}</b></p>)
		@plugin << %(             </div>)
		@plugin << %(           </div>)
		return @plugin
	end

end
