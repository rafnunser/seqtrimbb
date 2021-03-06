#########################################
# This class provided the methods to parse input options
#########################################

class OptionsParserSTBB

	def self.parse(args)

		#Creates options hash
		options = {}
		#Init OptionParser object
		optparse = OptionParser.new do |opts|
			#Set a banner, displayed at the top of the help screen.
			opts.banner = "Usage: /path/to/seqtrimbb -t template_file -Q seq_file [options]"
			#Cores
			options[:workers] = 1
			opts.on( '-w', '--workers COUNT', 'Number of threads' ) do |workers|
				begin
					options[:workers] = Integer(workers)
				rescue
					STDERR.puts "ERROR:Invalid threads parameter #{options[:workers]}"
					exit (-1)
				end
			end
			#Input file to process
			options[:file] = Array.new
			opts.on( '-Q', '--file FILE FILE1,FILE2',Array, 'Input fastq/fasta file' ) do |file|
				if !file.empty? && file.map { |f| File.exist?(File.expand_path(f)) }.all?
					options[:file] = file.map { |f| File.expand_path(f) }
				else
					STDERR.puts "ERROR. Sequences file: #{file.select{ |f| !File.exist?(f) }.join(" ")} does not exists"
					exit(-1)
				end
			end
			#Input qual file
			options[:qual] = Array.new
			opts.on( '-q', '--qual FILE1,FILE2',Array, 'Qual input file' ) do |file|
				if !file.empty? && file.map { |f| File.exist?(File.expand_path(f)) }.all?
					options[:qual] = file
				else
					STDERR.puts "ERROR. Sequences quality file: #{file.select{ |f| !File.exist?(f) }.join(" ")} does not exists"
					exit(-1)
				end
			end
			#Input template file
			options[:template] = ''
			opts.on( '-t', '--template TEMPLATE_FILE', 'Use TEMPLATE_FILE instead of default parameters' ) do |file|
				if !file.nil? && (File.exist?(File.expand_path(file)) || File.exist?(File.join(SEQTRIM_PATH,'templates',file)))
					options[:template] = File.exist?(File.expand_path(file)) ? File.expand_path(file) : File.join(SEQTRIM_PATH,'templates',file)
				else
					STDERR.puts "ERROR.Params file: #{file} doesn't exists. \n\nYou can use your own template or specify one from this list:\n=============================\n"
					STDERR.puts "#{Dir.glob(File.join(SEQTRIM_PATH,'templates','*.txt')).map{|t| File.basename(t)}.join("\n")}"
					exit(-1)
				end
			end
			#Output path
			options[:final_output_path] = File.expand_path('output_files')
			opts.on( '-O', '--ouput output_files', 'Output folder. It should not exists. output_files by default') do |folder|
				options[:final_output_path] = folder
			end
			#Skip final report
			options[:skip_report] = false
			opts.on( '-R', '--no-report', 'Do not generate final PDF report (gem scbi_seqtrimbb_report required if you want to generate PDF report).' ) do
				options[:skip_report] = true
			end
			#Generate output in gzip
			options[:write_in_gzip] = true
			opts.on( '-z','--no_gzip', 'Avoid generating output files in gzip format.' ) do
				options[:write_in_gzip] = false
			end
			#Force execution
			options[:force_execution] = false
			opts.on( '-F','--force', 'Force SeqtrimBB execution deleting previous output files' ) do
				options[:force_execution] = true
			end
			#Full throttle
			options[:full_throttle] = false
			opts.on( '--full_throttle', 'Avoid distributing cores, allocate -w value to each plugin.') do
				options[:full_throttle] = true
			end
			#Generate stats with FastQC
			options[:generate_initial_stats] = true
			options[:generate_final_stats] = true
			opts.on('-G','--generate_stats [OPTION]','Generate initial and/or final FastQC reports. Use -G to generate both reports, -G initial to generate just the initial report and -G final for the final report.') do |value|
				case value.to_s
					when ""
						options[:generate_initial_stats] = false
						options[:generate_final_stats] = false
					when 'initial'
						options[:generate_initial_stats] = false
					when 'final'                  
						options[:generate_final_stats] = false
				end
			end
			#Save unpaired
			options[:save_unpaired] = false
			opts.on('--save_unpaired', 'Save unpaired reads generated in some plugins' ) do
				options[:save_unpaired] = true
			end
			#Install databases trigger, an list of databases to install
			options[:install_db] = false
			options[:install_db_name] = Array.new
			opts.on( '-i', '--install_databases [DB_NAME]',Array,'If no DB_NAME is specified, install (or reinstall) all default databases provided with SeqTrimBB. Default databases can be modified with --databases_action,--databases_list options. If DB_NAME is update, SeqTrimBB will update provided databases.') do |value|
				options[:install_db] = true
				options[:install_db_name] = value if !value.nil?
			end
			#Check/Update databases trigger
			options[:check_db] = true
			opts.on( '-c', '--check_databases [RETRY]', 'Skip Checking databases step' ) do
				options[:check_db] = false
			end
			#List databases trigger and list
			options[:list_db] = false
			options[:list_db_name] = Array.new
			opts.on( '-L', '--list_db [DB_NAME]',Array,'List entries in DB_NAME. Use "-L" to view all available databases' ) do |value|
				options[:list_db] = true
				options[:list_db_name] = value if !value.nil?
			end
			#Action to be applied on databases cofiguration
			options[:databases_action]='replace'
			opts.on('--databases_action [ACTION]','Action to be applied to SeqtrimBB databases configuration: replace (replace SeqtrimBBs default databases list for one provided with --databases_list option), add (--databases_list list to default list) or remove (--databases_list list from default list). This option permanently modifies SeqTrimBBs configuration if user have write permissions. Default value is replace.') do |action|
				options[:databases_action] = action if !action.nil?
			end
			#List of databases to act with
			options[:databases_list] = Array.new
			opts.on('--databases_list [DATABASE] [DATABASE1,DATABASEN]',Array,'List of databases to replace/add/remove. To restore default list provided at installation time, execute SeqTrimBB with "--databases_list default".') do |database|
				options[:databases_list] = [database].flatten if !database.nil?
			end
			#To overwrite params that will be loaded later
			options[:overwrite_params] = nil
			opts.on('-P','--overwrite_params "PARAM1" "PARAM1;PARAM2"','Params and their values to overwrite default and templates parameters' ) do |oparams|
				options[:overwrite_params] = oparams
			end
			#Adds a cmd to the pipe
			options[:ext_cmd] = nil
			opts.on('--external_cmd EXTERNAL_CALL to insert in the pipe', 'Add one call (or more already piped between them) to an assembler or mapping tool' ) do |cmd|
				options[:ext_cmd] = cmd
			end
			#Change default outputfile name
			options[:outfilename] = ''
			opts.on('--outfilename [PREFIX]','Change output filename, by default use input filename as prefix') do |outname|
				if outname.to_s.empty?
					options[:outfilename] = 'default'
				else
					options[:outfilename] = outname
				end
			end
			#merge
			options[:merge_cmd] = false
			opts.on('-M','--merge_cmd','Merge input plugin with the first plugin in the list, and output plugin with the lasts (if they are mergeable)') do
				options[:merge_cmd] = true
			end
			# This displays the help screen, all programs are assumed to have this option.
			opts.on_tail('-h', '--help', 'Display this screen') do
				STDERR.puts "-----------------------------------------------\n"
				STDERR.puts opts
				#Fastq preprocessing
				STDERR.puts "\n\s\s========================================================================================================"
				STDERR.puts "\tE.g.: processing a paired sample in two fastq format files"
				STDERR.puts "\s\s========================================================================================================\n\n"
				STDERR.puts "\t#{File.basename($0)} -t template.txt -Q reads_1.fastq,reads_2.fastq"
				#Available templates
				STDERR.puts "\n\s\s========================================================================================================"
				STDERR.puts "  Available templates to use with -t option (you can also use your own template):"
				STDERR.puts "  Templates at: #{File.join(SEQTRIM_PATH,'templates')}"
				STDERR.puts "\s\s========================================================================================================\n\n"
				Dir.glob(File.join(SEQTRIM_PATH,'templates','*.txt')).map{|t| STDERR.puts "\t#{File.basename(t)}"}                     
				#exit					 
				exit(-1)
			end
		end
		# parse options and remove from ARGV
		optparse.parse!(args)
		options
	end
  #Help
	def self.help
		self.parse(['-h'])
	end

end