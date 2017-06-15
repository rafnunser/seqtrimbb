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

  # User's Filtering params

    user_filter_dbs = @params.get_param('user_filter_dbs')
    minratio = @params.get_param('user_filter_minratio')
    user_filter_aditional_params = @params.get_param('user_filter_aditional_params')
    user_filter_species = @params.get_param('user_filter_species')

  # Creates an array to store individual calls for every database in user_filter_dbs

    cmd_add = Array.new

  # Iteration to assemble individual calls

   user_filter_dbs.split(/ |,/).each do |db|

     # Creates an array to store the fragments

     cmd_add_add = Array.new

     # Adding invariable fragment

     cmd_add_add.push("bbsplit.sh -Xmx#{max_ram} t=#{cores} minratio=#{minratio}")

     # Adding necessary info to process sample as paired

     cmd_add_add.push("int=t") if sample_type == "paired" || sample_type == "interleaved"

     # Establish basic parameters based on database's nature:
     # db_refs (fasta file or folder containing sequences to filter by)
     # db_path (path to the folder containing sequences to filter by)
     # db_list (array of species present in database. Every fasta file is considered a species)

     if File.file?(db)
      
      #Single file database. TODO: grep '>' to separate sequences in the same file
       
       db_refs = db

       db_path = File.dirname(db)

       db_list = File.basename(db,".*")

     # Name and path for the statistics to be generated in the filtering process

       outstats = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_list}_user_filter_stats.txt")
       outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_list}_user_filter_stats_cmd.txt")

     else
      
       if File.exists?(db)

      #External directory database

         db_path = db
         db_refs = db
         db_name = db.split("/").last       

     # Name and path for the statistics to be generated in the filtering process

         outstats = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_user_filter_stats.txt")
         outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_user_filter_stats_cmd.txt")

      #Generate external database's index

         require 'check_external_database.rb'

         CheckDatabaseExternal.new(db,cores,max_ram)

      #Fill the array with the species presents in the external database

         db_list = Array.new
         path_refs = File.join(db,"old_fastas.txt")

         File.open(path_refs).each_line do |line|

           line.chomp!
           ref = File.basename(line,".fasta")
           species0 = ref.split("_")
           species= species0.join(" ")
           db_list.push(species)

         end

       else
        
      # Internal directory database

         db_path = File.join($DB_PATH,db)
         db_refs = File.join($DB_PATH,db)

     # Name and path for the statistics to be generated in the filtering process

         outstats = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_user_filter_stats.txt")
         outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_user_filter_stats_cmd.txt")

      #Fill the array with the species presents in the external database

         db_list = Array.new
         path_refs = File.join(db_path,'old_fastas_'+db+'.txt')

         File.open(path_refs).each_line do |line|

           line.chomp!
           ref = File.basename(line,".fasta")
           species0 = ref.split("_")
           species= species0.join(" ")
           db_list.push(species)

         end
       end
     end

     # Filtering 

     cmd_add_add.push("ref=#{db_refs} path=#{db_path}")

     # Adding details to filter out species

     if user_filter_species != nil

      splitted_species = user_filter_species.split(",")

      splitted_species.each do |species|

       species_full0 = species.split(" ")
       species_full = species_full0.join("_")

       cmd_add_add.push("out_#{species_full}=#{species_full}_out.fastq.gz") if db_list.include?(species)

      end

     else

      cmd_add_add.push("basename=%_out.fastq.gz")

     end

     # Adding closing args to the call

      if user_filter_aditional_params != nil

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

  user_filter_dbs = @params.get_param('user_filter_dbs')

    plugin_stats = {}
    plugin_stats["plugin_user_filter"] = {}
    plugin_stats["plugin_user_filter"]["filtered_sequences_count"] = 0
    plugin_stats["plugin_user_filter"]["filtering_ids"] = {}

  user_filter_dbs.split(/ |,/).each do |db|

   if File.file?(db)

        db_name = File.basename(db,".*")

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

        if (line =~ /Exception in thread/)

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

    comment='Databases to use in Filtering: internal name or full path to fasta file or full path to a folder containing an external database in fasta format' 
    default_value = 'contaminants'
    params.check_param(errors,'user_filter_dbs','String',default_value,comment)

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
