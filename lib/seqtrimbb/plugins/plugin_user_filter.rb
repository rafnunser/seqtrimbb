########################################################
# Defines the main methods that are necessary to filter out reads based on similarity with an entry in a given database
########################################################

class PluginUserFilter < Plugin

  #Returns an array with the errors due to parameters are missing 
      def check_params

        #Priority, base ram
             cores = []
             priority = 2
             ram = []
             base_ram = 720 #mb
        #Array to store errors        
             errors=[]  
        #Check params (errors,param_name,param_class,default_value,comment) 
             @params.check_param(errors,'user_filter_db','DB','','Databases to use in Filtering: internal name or full path to fasta file or full path to a folder containing an external database in fasta format',@stbb_db)
             #Adds 1 core for each database
             @params.get_param('user_filter_db').split(/ |,/).each do |database|
                     cores << 1
                     ram << (@stbb_db.get_info(database,'index_size')/2.0**20).round(0) + base_ram 
             end

             @params.check_param(errors,'user_filter_minratio','String','0.56','Minimal ratio of sequence of interest kmers in a read to be filtered')

             @params.check_param(errors,'user_filter_species','String',nil,'list of species (fasta files names in database comma separated) to filter out')
    
             @params.check_param(errors,'user_filter_aditional_params','String',nil,'Aditional BBsplit parameters, add them together between quotation marks and separated by one space')
        #Set resources
             @params.resource('set_requirements',{ 'plugin' => 'PluginUserFilter','opts' => {'cores' => cores,'priority' => priority,'ram'=>ram}})
        #Make filtered directory
             Dir.mkdir(File.join(File.expand_path(OUTPUT_PATH),'filtered_files')) if !Dir.exist?(File.join(File.expand_path(OUTPUT_PATH),'filtered_files'))

             return errors    

      end
  #Get options
      def get_options

           #Creates an array to store individual options for every database in contaminants_dbs
             opts = Array.new
           #Iteration to assemble individual options
             @params.get_param('user_filter_db').split(/ |,/).each do |db|                       
                    # Add hash to array
                     opts << get_filtering_module(db,'user_filter')
                     
             end
         #Return
           return opts

      end 
  #Get module
      def get_filtering_module(db,plugin)
          
             module_options = super
           #Species to filter out
             user_filter_species = @params.get_param('user_filter_species')
           #output files suffix
             @suffix = ['_pre_out',@params.get_param('sample_type') == 'paired' ? '_#' : '',@params.get_param('suffix')].join('')
          # Adding details to filter out species. Check species if needed
             if !user_filter_species.nil?
                     user_filter_species.split(/,/).each do |species|
                             module_options["out_#{species.split(" ").join("_")}"] = "#{File.join(File.expand_path(OUTPUT_PATH),"filtered_files")}/#{species.split(" ").join("_")}#{@suffix}" if @stbb_db.get_info(db,'list').include?(species)
                     end
             else
                     module_options['basename'] = "#{File.join(File.expand_path(OUTPUT_PATH),"filtered_files")}/%#{@suffix}"
             end

             return module_options

      end
  #Get cmd
      def get_cmd(result_hash)
            
            #Load all databases cmds
             full_cmd = Array.new
             result_hash['opts'].each do |opt_hash|
                     full_cmd << @bbtools.load_bbsplit(opt_hash)    
             end
            #Return
             return full_cmd.join(' | ')

      end
  #Get stats
      def get_stats(stats_files,stats)

             stats["plugin_user_filter"] = {} if !stats.key?('plugin_user_filter')
             stats["plugin_user_filter"]["filtered_sequences_count"] = 0 if !stats['plugin_user_filter'].key?('filtered_sequences_count')
             stats["plugin_user_filter"]["filtering_ids"] = {} if !stats['plugin_user_filter'].key?('filtering_ids')
         #Regexp
             regexp_str = "^(?!\s*#).+"
         #For every database refstats
             stats_files['stats'].each do |refstats_file|
                     lines = super(regexp_str,refstats_file)
                     lines.each do |line|
                             splitted_line = line.split(/\t/)
                             nreads = splitted_line[5].to_i + splitted_line[6].to_i
                             stats["plugin_user_filter"]["filtering_ids"][splitted_line[0]] = nreads
                             stats["plugin_user_filter"]["filtered_sequences_count"] += nreads
                     end
             end
      end
  #CLEAN UP
      def clean_up

         #Apply minlength to filtered files!
             filtered_files = Dir[File.join(File.expand_path(OUTPUT_PATH),"filtered_files","*.fastq*")].sort
             return if filtered_files.empty?
             slice_size = @params.get_param('sample_type') == 'paired' ? 2:1
             filtered_files = filtered_files.each_slice(slice_size).to_a
             remove_short_reads(filtered_files,'pre_','')
         #Remove emptied files
             remove_empty_files(Dir[File.join(File.expand_path(OUTPUT_PATH),"filtered_files","*.fastq*")].sort)

      end

      def remove_empty_files(files)

             files.each do |fastq_file|
         #Test if file is empty
                    openfile = @params.get_param('write_in_gzip') ? Zlib::GzipReader.new(open(fastq_file)) : open(fastq_file)
                    res = true
                    openfile.each_line do |line|
                           if !line.empty?
                                   res = false
                                   break            
                           end
                    end
                    openfile.close
                    FileUtils.rm(fastq_file) if res
             end

      end

      def remove_short_reads(files,to_remove,to_add)

             files.each do |file_array|
                     outfiles = file_array.map { |file| file.sub(/#{to_remove}/,to_add) }
                     h = { 'in' => file_array[0],'out' => outfiles[0],'minlength' => @params.get_param('minlength'),'ow' => 't','redirection' => ['2>','/dev/null']}
                     if @params.get_param('sample_type') == 'paired' && outfiles.count == 2
                             h['in2'] = file_array[1]
                             h['out2'] = outfiles[1]
                             h['int'] = 'f'
                     end
                     system(@bbtools.load_reformat(h))
                     file_array.each_with_index { |file,i| FileUtils.rm(file) if File.exist?(outfiles[i]) }
             end

      end

end
