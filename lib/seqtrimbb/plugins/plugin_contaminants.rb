require "plugin"

########################################################
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginContaminants < Plugin
  
 def get_cmd

  # General params
    max_ram = @params.get_param('max_ram')
    cores = @params.get_param('workers')
    sample_type = @params.get_param('sample_type')

    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')

  # Contaminant's Filtering params
    contaminants_dbs = @params.get_param('contaminants_db')
    minratio = @params.get_param('contaminants_minratio')
    contaminants_aditional_params = @params.get_param('contaminants_aditional_params')
    decontamination_mode = @params.get_param('contaminants_decontamination_mode')
    sample_species = @params.get_param('sample_species')
    mode_details = decontamination_mode.downcase.split(" ")

  # Creates an array to store individual calls for every database in contaminants_dbs
    cmd_add = Array.new

  # Iteration to assemble individual calls
  contaminants_dbs.split(/ |,/).each do |db|

     # Creates an array to store the fragments
      cmd_add_add = Array.new

     # Adding invariable fragment
      cmd_add_add.push("java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio}")

     # Adding necessary info to process sample as paired
      cmd_add_add.push("int=t") if sample_type == 'paired' || sample_type == 'interleaved'

     # Establish basic parameters based on database's nature:
     # db_refs (fasta file or folder containing contaminant's sequences)
     # db_path (path to the folder containing contaminant's sequences)
     # db_list (array of species present in database. Every fasta file is considered a species)
   
   if File.file?(db)

        #Extract info
        db_update = CheckDatabaseExternal.new(db,cores,max_ram)
        db_info = db_update.info
      # Single-file database
        db_refs = db
        db_index = db_info["db_index"]
        db_name = db_info["db_name"]
        db_list = {}
        db_list[db_name] = db
      # Adding database's specific fragment considering decontamination mode.
      # Regular decontamination mode
      if mode_details[0] == 'regular'
        cmd_add_add.push("path=#{db_index}")
      end

   else  

      db_list = {}

      if Dir.exists?(db)
        #Extract info
        db_update = CheckDatabaseExternal.new(db,cores,max_ram)
        db_info = db_update.info
      #External directory database
        db_index = db_info["db_index"]
        db_name = db_info["db_name"]
        path_refs = db_info["db_fastas"]

      else
      # Internal directory database
         db_index = File.join($DB_PATH,'indices',db)
         db_name = db
         path_refs = File.join($DB_PATH,'status_info','fastas_'+db+'.txt')
      end

     #Fill the array with the species presents in the external database
      File.open(path_refs).each_line do |line|
       line.chomp!
       species = File.basename(line).split(".")[0].split("_")[0..1].join(" ")
       db_list[species] = line
      end 

    # Adding database's specific fragment considering decontamination mode.
    # Regular decontamination mode
      if mode_details[0] == 'regular'
        cmd_add_add.push("path=#{db_index}")
      end

     # Excluding decontamination mode
      if mode_details[0] == 'exclude'
        if [nil,'',' '].include?(sample_species)
           $LOG.error "PluginContaminants: Sample species param is empty and decontamination mode is #{decontamination_mode}. Specify #{mode_details[1]}, or change decontamination_mode to regular"
           exit -1
        end
        # Creates an array to store the paths to selected fastas 
         db_ref = Array.new
        # Extract sample species detailed info
         sample_genus = sample_species.split(" ")[0]
        # First test contaminants in database for compatibility with the sample's species, then add the proper contaminants
         db_list.each do |contaminant,path|
            contaminant_genus = contaminant.split(" ")[0]
            db_ref.push(path) if contaminant_genus != sample_genus && mode_details[1] == 'genus'
            db_ref.push(path) if contaminant != sample_species && mode_details[1] == 'species'
         end
       
         db_refs = db_ref.join(",")
         index_path = File.join(OUTPUT_PATH,'temp_indices',db_name)
         FileUtils.rm_rf(index_path) if Dir.exists?(index_path)
         FileUtils.mkdir(index_path)
         cmd_add_add.push("ref=#{db_refs} path=#{index_path}")
      end

    end

    # Name and path for the statistics to be generated in the decontamination process

   outstats = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_contaminants_stats.txt")
   outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_contaminants_stats_cmd.txt")

    # Adding closing args to the call

   cmd_add_add.push(contaminants_aditional_params) if !contaminants_aditional_params.nil?
   closing_args = "in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"
   cmd_add_add.push(closing_args)

    # Assembling the call and adding it to the plugins result
    
   cmd_add.push(cmd_add_add.join(" "))

  end
    # Joining the calls in a single element

    cmd = cmd_add.join(" | ")
    return cmd

 end

 def get_stats

  contaminants_dbs = @params.get_param('contaminants_db')

  plugin_stats = {}
  plugin_stats["plugin_contaminants"] = {}
  plugin_stats["plugin_contaminants"]["contaminated_sequences_count"] = 0
  plugin_stats["plugin_contaminants"]["contaminants_ids"] = {}

  contaminants_dbs.split(/ |,/).each do |db|

   if File.file?(db)
        db_name = File.basename(db,".fasta")
        stat_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_contaminants_stats.txt")
        cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_contaminants_stats_cmd.txt")
   else
      if File.exists?(db)
         db_name = db.split("/").last
         stat_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_contaminants_stats.txt")
         cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_contaminants_stats_cmd.txt")
      else
         stat_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_contaminants_stats.txt")   
         cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_contaminants_stats_cmd.txt")   
      end  
   end

    # First look for internal errors in cmd execution

     File.open(cmd_file).each do |line|
      line.chomp!
      if !line.empty?
        if (line =~ /Exception in thread/) || (line =~ /Error\S/)
           STDERR.puts "Internal error in BBtools execution. For more details: #{cmd_file}"
           exit -1 
        end
      end
     end

    # Extracting stats 

    File.open(stat_file).each do |line|
      line.chomp!
     if !line.empty?
       if !(line =~ /^\s*#/) 
         splitted = line.split(/\t/)
         nreads = splitted[5].to_i + splitted[6].to_i
         plugin_stats["plugin_contaminants"]["contaminants_ids"][splitted[0]] = nreads
         plugin_stats["plugin_contaminants"]["contaminated_sequences_count"] += nreads
       end
     end
    end

    return plugin_stats

  end

 end
 
  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    
    errors=[]  
   
    comment='Max RAM'
    default_value = 
    params.check_param(errors,'max_ram','String',default_value,comment)

    comment='Number of Threads'
    default_value = 1
    params.check_param(errors,'workers','String',default_value,comment)

    comment='Type of sample: paired, single-ended or interleaved.'
    default_value = 
    params.check_param(errors,'sample_type','String',default_value,comment)

    comment='Databases to use in decontamination: internal name or full path to fasta file or full path to a folder containing an external database in fasta format' 
    default_value = 'contaminants'
    params.check_param(errors,'contaminants_db','DB',default_value,comment)

    comment='Minimal ratio of contaminants kmers in a read to be deleted' 
    default_value = '0.56'
    params.check_param(errors,'contaminants_minratio','String',default_value,comment)

    comment='Decontamination mode: regular to just delete contaminated reads, or excluding to avoid deleting reads using contaminant species similar (genus or species) to the samples species, use excluding genus for a conservative approach or excluding species for maximal sensibility.'
    default_value = 'regular'
    params.check_param(errors,'contaminants_decontamination_mode','String',default_value,comment)

    comment='Species of the sample to process'
    default_value = nil
    params.check_param(errors,'sample_species','String',default_value,comment)
    
    comment='Aditional BBsplit parameters, add them together between quotation marks and separated by one space'
    default_value = nil
    params.check_param(errors,'contaminants_aditional_params','String',default_value,comment)

    return errors
  end

end
