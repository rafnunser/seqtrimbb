require "plugin"

########################################################
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginUserFilter < Plugin
  
 def get_cmd

  # General params
    max_ram = @params.get_param('max_ram')
    cores = @params.get_param('workers')
    sample_type = @params.get_param('sample_type')
    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')

  # User's Filtering params
    user_filter_dbs = @params.get_param('user_filter_db')
    minratio = @params.get_param('user_filter_minratio')
    user_filter_aditional_params = @params.get_param('user_filter_aditional_params')
    user_filter_species = @params.get_param('user_filter_species')
    minlength = @params.get_param('minlength')
    write_in_gzip = @params.get_param('write_in_gzip')
    output = File.join(File.expand_path(OUTPUT_PATH),"filtered_files")

  # Creates an array to store individual calls for every database in user_filter_dbs
    cmd_add = Array.new

  # Discards reads with length < minlength
    pre_cmd = Array.new

    preoutstats = File.join(File.expand_path(OUTPLUGINSTATS),"user_filter_stats_minlength_discard.txt")

    pre_cmd.push("java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores} in=stdin.fastq minlength=#{minlength}")
    pre_cmd.push("int=t") if sample_type == "paired" || sample_type == "interleaved"
    pre_cmd.push("out=stdout.fastq 2> #{preoutstats}")
    cmd_add.push(pre_cmd.join(" "))

  # Iteration to assemble individual calls
   user_filter_dbs.split(/ |,/).each do |db|

     # Creates an array to store the fragments
     cmd_add_add = Array.new

     # Adding invariable fragment
     cmd_add_add.push("java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio}")

     # Adding necessary info to process sample as paired
     cmd_add_add.push("int=t") if sample_type == "paired" || sample_type == "interleaved"

     # Establish basic parameters based on database's nature:
     # db_refs (fasta file or folder containing sequences to filter by)
     # db_path (path to the folder containing sequences to filter by)
     # db_list (array of species present in database. Every fasta file is considered a species)

     if File.file?(db)
        db_update = CheckDatabaseExternal.new(db,cores,max_ram)
        db_info = db_update.info
      # Single-file database
        db_refs = db
        db_index = db_info["db_index"]
        db_name = db_info["db_name"]
        db_list = File.basename(db,".*").split("_")[0..1].join(" ")
     else
       db_list = Array.new    
       if Dir.exists?(db)
        db_update = CheckDatabaseExternal.new(db,cores,max_ram)
        db_info = db_update.info
      #External directory database
        db_refs = db
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
       db_list.push(species)
      end
    end

     # Name and path for the statistics to be generated in the filtering process

     outstats = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_user_filter_stats.txt")
     outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_user_filter_stats_cmd.txt")
     # Filtering 

     cmd_add_add.push("path=#{db_index}")

     # Adding details to filter out species

     if write_in_gzip   
        suffix = 'fastq.gz'
     else
         suffix = 'fastq'
     end

     if !user_filter_species.nil?
      user_filter_species.split(",").each do |species|
       species_full = species.split(" ").join("_")
       cmd_add_add.push("out_#{species_full}=#{output}/#{species_full}_out.#{suffix}") if db_list.include?(species) && (sample_type == "interleaved" || sample_type == "single-ended")
       cmd_add_add.push("out_#{species_full}=#{output}/#{species_full}_out_#.#{suffix}") if db_list.include?(species) && sample_type == "paired"
      end
     else
      cmd_add_add.push("basename=#{output}/%_out.#{suffix}") if sample_type == "interleaved" || sample_type == "single-ended"
      cmd_add_add.push("basename=#{output}/%_out_#.#{suffix}") if sample_type == "paired"
     end

     # Adding closing args to the call
     if !user_filter_aditional_params.nil?
        cmd_add_add.push(user_filter_aditional_params)
     end

     closing_args = "in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"    
     cmd_add_add.push(closing_args)

     # Assembling the call and adding it to the plugins result
 
     db_cmd = cmd_add_add.join(" ")
     cmd_add.push(db_cmd)

   end
    
    # Joining the calls in a single element

    cmd = cmd_add.join(" | ")

    return cmd

 end
 
 def get_stats

  user_filter_dbs = @params.get_param('user_filter_db')

    plugin_stats = {}
    plugin_stats["plugin_user_filter"] = {}
    plugin_stats["plugin_user_filter"]["filtered_sequences_count"] = 0
    plugin_stats["plugin_user_filter"]["filtering_ids"] = {}

  user_filter_dbs.split(/ |,/).each do |db|

   if File.file?(db)
        db_name = File.basename(db).split(".")[0]
        stat_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_user_filter_stats.txt")
        cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_user_filter_stats_cmd.txt")

   else
      if File.exists?(db)
         db_name = db.split("/").last
         stat_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_user_filter_stats.txt")
         cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_user_filter_stats_cmd.txt")
      else
         stat_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_user_filter_stats.txt")   
         cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_user_filter_stats_cmd.txt")
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
       if !(line =~ /^\s*#/) #Es el encabezado de la tabla o el archivo   
         splitted = line.split(/\t/)
         nreads = splitted[5].to_i + splitted[6].to_i
         plugin_stats["plugin_user_filter"]["filtering_ids"][splitted[0]] = nreads
         plugin_stats["plugin_user_filter"]["filtered_sequences_count"] += nreads
       end
     end
    end
  end

  # Remove empty files from filtered_files

  
  return plugin_stats

 end

  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]  
   
    comment='Max RAM'
    default_value = 
    params.check_param(errors,'max_ram','String',default_value,comment)

    comment='Write in gzip?'
    default_value = 
    params.check_param(errors,'write_in_gzip','String',default_value,comment)

    comment='Number of Threads'
    default_value = 
    params.check_param(errors,'workers','String',default_value,comment)

    comment='Minimal reads length to be keep' 
    default_value = '50'
    params.check_param(errors,'minlength','String',default_value,comment)

    comment='Type of sample: paired, single-ended or interleaved.'
    default_value = 
    params.check_param(errors,'sample_type','String',default_value,comment)

    comment='Databases to use in Filtering: internal name or full path to fasta file or full path to a folder containing an external database in fasta format' 
    default_value =''
    params.check_param(errors,'user_filter_db','DB',default_value,comment)

    comment='Minimal ratio of sequence of interest kmers in a read to be filtered' 
    default_value = '0.56'
    params.check_param(errors,'user_filter_minratio','String',default_value,comment)
  
    comment='list of species (fasta files names in database comma separated) to filter out' 
    default_value = nil
    params.check_param(errors,'user_filter_species','String',default_value,comment)

    comment='Aditional BBsplit parameters, add them together between quotation marks and separated by one space'
    default_value = nil
    params.check_param(errors,'user_filter_aditional_params','String',default_value,comment)

    return errors
  end

end
