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

  # Contaminant's Filtering params

    contaminants_dbs = @params.get_param('contaminants_dbs')
    minratio = @params.get_param('contaminants_minratio')
    contaminants_aditional_params = @params.get_param('contaminants_aditional_params')
    decontamination_mode = @params.get_param('contaminants_decontamination_mode')
    sample_species = @params.get_param('sample_species')

  # Creates an array to store individual calls for every database in contaminants_dbs

    cmd_add = Array.new

  # Iteration to assemble individual calls

  contaminants_dbs.split(/ |,/).each do |db|

     # Name and path for the statistics to be generated in the decontamination process

      outstats = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_contaminants_stats.txt")

     # Creates an array to store the fragments

      cmd_add_add = Array.new

     # Adding invariable fragment

      cmd_add_add.push("bbsplit.sh -Xmx#{max_ram} t=#{cores} minratio=#{minratio}")

     # Adding necessary info to process sample as paired

      cmd_add_add.push("int=t") if sample_type == 'paired' || sample_type == 'interleaved'

     # Establish basic parameters based on database's nature:
     # db_refs (fasta file or folder containing contaminant's sequences)
     # db_path (path to the folder containing contaminant's sequences)
     # db_list (array of species present in database. Every fasta file is considered a species)

   if File.file?(db)
      
      #Single file database. TODO: grep '>' to separate sequences in the same file

      # Name and path for the statistics to be generated in the decontamination process

        db_name = File.basename(db,".fasta")

        outstats = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_contaminants_stats.txt")
       
        db_refs = db

        db_path = File.dirname(db)

        db_list = File.basename(db,".*")

   else
      
      if File.exists?(db)

      #External directory database

          db_path = db

          db_refs = db

      # Name and path for the statistics to be generated in the decontamination process

         db_name = db.split("/").last

         outstats = File.join(File.expand_path(OUTPLUGINSTATS),"#{db_name}_contaminants_stats.txt")
 
      #Generate external database's index

         require 'check_external_database.rb'

         CheckDatabaseExternal.new(db,cores,max_ram)

      #Fill the array with the species presents in the external database

         db_list = {}

         path_refs = File.join(db,"old_fastas.txt")

         File.open(path_refs).each_line do |line|

           line.chomp!
           ref = File.basename(line,".fasta")
           species0 = ref.split("_")
           species= species0[0..1].join(" ")

           db_list[species] = line

         end

      else

      # Name and path for the statistics to be generated in the decontamination process

         outstats = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_contaminants_stats.txt")
        
      # Internal directory database

         db_path = File.join($DB_PATH,db)
         db_refs = File.join($DB_PATH,db)

      #Fill the array with the species presents in the external database

         db_list = {}
        
         path_refs = File.join(db_path,'old_fastas_'+db+'.txt')

         File.open(path_refs).each_line do |line|

           line.chomp!
           ref = File.basename(line,".fasta")
           species0 = ref.split("_")
           species= species0[0..1].join(" ")

           db_list[species] = line

         end

      end
        
   end

    # Adding database's specific fragment considering decontamination mode. First split decontamination mode to show it's details.

   mode_details = decontamination_mode.downcase.split(" ")

    # Regular decontamination mode

   if mode_details[0] == 'regular'

         cmd_add_add.push("ref=#{db_refs} path=#{db_path}")

   end

     # Excluding decontamination mode

   if mode_details[0] == 'exclude'

        # Creates an array to store the paths to selected fastas 

         db_ref = Array.new

        # Extract sample species detailed info

         sample_species_details = sample_species.split(" ")
         sample_genus = sample_species_details[0]

        # First test contaminants in database for compatibility with the sample's species, then add the proper contaminants

         db_list.each do |contaminant,path|

           contaminant_path = path

           if mode_details[1] == 'genus'

             contaminant_species = contaminant.split(" ")
             contaminant_genus = contaminant_species[0]

             db_ref.push(contaminant_path) if contaminant_genus != sample_genus

           else 
             
             db_ref.push(contaminant_path) if contaminant != sample_species

           end

         end
       
        db_refs = db_ref.join(",")

        index_path = File.expand_path(OUTPUT_PATH)
        cmd_add_add.push("ref=#{db_refs} path=#{index_path}")

   end

    # Adding closing args to the call


   if contaminants_aditional_params != nil

      cmd_add_add.push(contaminants_aditional_params)

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

    comment='Databases to use in decontamination: internal name or full path to fasta file or full path to a folder containing an external database in fasta format' 
    default_value = 'contaminants'
    params.check_param(errors,'contaminants_dbs','String',default_value,comment)

    comment='Minimal ratio of contaminants kmers in a read to be deleted' 
    default_value = '0.56'
    params.check_param(errors,'contaminants_minratio','String',default_value,comment)

    comment='Decontamination mode: regular to just delete contaminated reads, or excluding to avoid deleting reads using contaminant species similar (genus or species) to the samples species, use excluding genus for a conservative approach or excluding species for maximal sensibility.'
    default_value = 'regular'
    params.check_param(errors,'contaminants_decontamination_mode','String',default_value,comment)

    comment='Species of the sample to process'
    default_value = 
    params.check_param(errors,'sample_species','String',default_value,comment)
    
    comment='Aditional BBsplit parameters, add them together between quotation marks and separated by one space'
    default_value = nil
    params.check_param(errors,'contaminants_aditional_params','String',default_value,comment)

    return errors
  end

end
