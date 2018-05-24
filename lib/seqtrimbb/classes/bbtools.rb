########################################################
# Defines the methods that are necessary to load a BBtools module
########################################################

class BBtools

	#INIT
	def initialize(dir)
		#TODO: read modules from sh files in bbtools path
		#BBTools dirs
		classp = File.join(dir,'current')
		nativelibdir = File.join(dir,'jni')
		#Store modules in a hash
		@modules = {}
		@modules['reformat'] = "java -ea -cp #{classp} jgi.ReformatReads t=INSERT_CORES -XmxINSERT_RAM"
		@modules['bbduk'] = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} jgi.BBDukF t=INSERT_CORES -XmxINSERT_RAM -XmsINSERT_RAM"
		@modules['bbsplit'] = "java -Djava.library.path=#{nativelibdir} -ea -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 t=INSERT_CORES -XmxINSERT_RAM"
		@modules['splitnextera'] = "java -ea -cp #{classp} jgi.SplitNexteraLMP t=INSERT_CORES -XmxINSERT_RAM"
		@modules['testformat'] = "java -ea -cp #{classp} fileIO.FileFormat -XmxINSERT_RAM"
		#Default options
		@default_options = {'in' => 'stdin.fastq', 'out' => 'stdout.fastq', 'int' => 't'}
		#Define modules
		load_modules
	end
	#DEFINE METHODS to load a BBtools module with specific options (from plugins)
	def load_modules
		#For each key in @modules hash define a method
		@modules.keys.each do |module_bb|
		#LOAD
			define_singleton_method("load_#{module_bb}") do |module_options|
		#Preload default options and calls invariable fragment
				cmd = []
				cmd << get_module(module_bb)
		#Build cmd with merged options
				concatenate_options(@default_options.merge(module_options),cmd)
		#Return loaded cmd
				return cmd.join(" ")
			end
		end    
	end
	#Get module
	def get_module(module_bb)
		return @modules[module_bb].clone
	end
	#Load specific options in to the module
	def concatenate_options(options,cmd) 
		redirection = options.delete('redirection') if options.key?('redirection')
		options.each do |opt,arg|
			if opt == "ram" || opt == "cores"
				if arg.nil? && opt == "cores"
					expr = "t=INSERT_#{opt.upcase}"
					arg = ''			
				elsif arg.nil? && opt == "ram"
					expr = "-Xm(x|s)INSERT_#{opt.upcase}"
					arg = ''									
				else
					expr = "INSERT_#{opt.upcase}"				
				end
				cmd.each { |frag| frag.gsub!(/#{expr}/,arg.to_s)}
				next
			end
			if !arg.is_a?(Array) && !arg.nil?
				cmd << "#{opt}=#{arg}"
			elsif arg.is_a?(Array) && !arg.empty?
				cmd << arg.compact.join(" ")
			end       
		end
		cmd << redirection if defined?(redirection)
		#Return concatenate options string
		return cmd
	end
	#Store default options
	def store_default(options)
		@default_options = options
	end
	#Merge default options
	def merge_default(options)
		@default_options.merge!(options)
	end

end