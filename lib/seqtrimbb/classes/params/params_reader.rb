#########################################
# This class provided the methods to read the parameters from file or options, and to save them
#########################################

class ParamsReader < Params

	def initialize; end
  	# Reads param's file
	def read_file(path_file)  
		comments= []
		open_path_file = File.open(path_file)
		open_path_file.each_line do |line|
			line.chomp! # delete end of line
			if !line.empty?
				if !(line =~ /^\s*#/)   # if line is not a comment
						# extract the parameter's name in params[0] and the parameter's value in params[1]
						line =~ /^\s*([^=]*)\s*=*\s*(.*)\s*$/
						par=[$1,$2]          
						# store in the hash the pair key/value, in our case will be name/value ,
						# that are save in params[0] and params[1],  respectively
					if (!par[0].nil?) && (!par[1].nil?)
						set_param(par[0].strip,par[1].strip,comments)
						comments=[]
					end
				elsif (line =~ /^\s*#/)
					comments << line.gsub(/^\s*#/,'')
				end 
			end 
		end 
		open_path_file.close
		if @@params.empty?
			STDERR.puts "WARNING. EMPTY PARAMETER FILE: #{path_file}. No parameters defined"
		end
	end
  	# Save options
	def save_options(options)
		options.each do |opt_name,opt_value|
			set_param(opt_name.to_s,opt_value,"#{opt_name} value from input options")
		end
	end
  # Process saved params to add new useful general params
	def process_params(bbtools)
	 # Writing options
		suffix = get_param('write_in_gzip') ? '.fastq.gz' : '.fastq'
		set_param('suffix',suffix,"# Output files file extension")
	 # test inputfiles format
		if !get_param('file').nil? && File.exist?(get_param('file')[0].to_s)
			format_info = %x[#{bbtools.load_testformat({'ram' => '50m', 'in' => nil,'int' => nil,'out' => nil,'files' => [get_param('file')[0]]})}].split(" ")
	 # Set format info (test number of files for paired)
			set_param('qual_format',format_info[0],"# Quality format value from input files")
			set_param('file_format',format_info[1],"# File format value from input files")
			set_param('sample_type',get_param('file').count == 2 ? 'paired' : format_info[3],"# Sample type value from input files")
			set_param('read_length',format_info[4],"# Read read_length")
	 # Preloading output params 
	 # Setting outputfiles 
			set_param('outputfile',preset_outputfiles,"# Preloaded output files")
	 #Set and store default options. First add paired/interleaved information
			paired = (get_param('sample_type') == 'paired' || get_param('sample_type') == 'interleaved') ? 't' : 'f'
			default_options = { "in" => "stdin.fastq", "out" => "stdout.fastq", "int" => paired }
			set_param('default_options',default_options,"# Preloaded default BBtools input/output/paired_info")
			bbtools.store_default(default_options)
		end
	 # Finally Overwrite template's params with option -P params
		get_param('overwrite_params').split(";").each { |param| overwrite_param(param) } if !get_param('overwrite_params').nil?
	end
	 #Preset outpufiles
	def preset_outputfiles
		#Save prefix
		if get_param('outfilename').empty?
			case get_param('sample_type')
				when 'paired'
					prefix = 'paired'
				when 'interleaved'
					prefix = 'interleaved'
				when 'single-ended'
					prefix = 'sequences_'
			end
		elsif get_param('outfilename') == 'default'
			prefix = get_param('file').first.to_s.sub(/.fastq(.gz)?$/,'')
			prefix.sub!(/_?(pair|R)?(1|2)$/,'') if get_param('sample_type') == 'paired'
			prefix = prefix + '_cleaned'
		else
			prefix = get_param('outfilename')
		end
		#Return
		case get_param('sample_type')
			when 'paired'
				return [File.join(File.expand_path(OUTPUT_PATH),"#{prefix}_1#{get_param('suffix')}"),File.join(File.expand_path(OUTPUT_PATH),"#{prefix}_2#{get_param('suffix')}")]
			when 'interleaved'
				return [File.join(File.expand_path(OUTPUT_PATH),"#{prefix}#{get_param('suffix')}")]
			when 'single-ended'
				return [File.join(File.expand_path(OUTPUT_PATH),"#{prefix}#{get_param('suffix')}")]
		end

	end
	  
end