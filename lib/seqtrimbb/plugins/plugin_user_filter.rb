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
    minratio = @params.get_param('filter_minratio')
    user_filter_aditional_params = @params.get_param('user_filter_aditional_params')
    user_filter_species = @params.get_param('user_filter_species')

  # Creates an array to store individual calls for every database in user_filter_dbs

    cmd_add = Array.new

  # Iteration to assemble individual calls

   user_filter_dbs.split(",").each do |db|

     # Name and path for the statistics to be generated in the filtering process

     outstats = File.join(File.expand_path(OUTPUT_PATH),"#{db}_user_filter_stats.txt")

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

     else
      
       if File.exists?(db)

      #External directory database

         db_path = db
         db_refs = db

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

     splitted_species = user_filter_species.split(",")

     splitted_species.each do |species|

       species_full0 = species.split(" ")
       species_full = species_full0.join("_")

       cmd_add_add.push("out_#{species_full}=#{species_full}_out.fastq.gz") if db_list.include?(species)

     end

     # Adding closing args to the call

      if user_filter_aditional_params != 'false'

        cmd_add_add.push(user_filter_aditional_params)

      end

     closing_args = "in=stdin.fastq out=stdout.fastq refstats=#{outstats}"    
     cmd_add_add.push(closing_args)

     # Assembling the call and adding it to the plugins result
 
     db_cmd = cmd_add_add.join(" ")
     cmd_add.push(db_cmd)

   end
    
    # Joining the calls in a single element

    cmd = cmd_add.join(" | ")

    return cmd

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
    params.check_param(errors,'filter_minratio','String',default_value,comment)
  
    comment='list of species (fasta files names in database comma separated) to filter out' 
    default_value = 
    params.check_param(errors,'user_filter_species','String',default_value,comment)

    comment='Aditional BBsplit parameters, add them together between quotation marks and separated by one space'
    default_value = 'false'
    params.check_param(errors,'user_filter_aditional_params','String',default_value,comment)

    return errors
  end

end
