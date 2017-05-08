require "plugin"

########################################################
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginVectors < Plugin
  
 def get_cmd

  # General params

    max_ram = @params.get_param('max_ram')
    cores = @params.get_param('workers')
    sample_type = @params.get_param('sample_type')
    save_singles = @params.get_param('save_unpaired')

    cmd_add = Array.new

  # Vectors trimming params

    vectors_db = @params.get_param('vectors_db')
    vectors_trimming_position = @params.get_param('vectors_trimming_position')
    vectors_kmer_size = @params.get_param('vectors_kmer_size')
    vectors_min_external_kmer_size = @params.get_param('vectors_min_external_kmer_size')
    vectors_max_mismatches = @params.get_param('vectors_max_mismatches')
    vectors_trimming_aditional_params = @params.get_param('vectors_trimming_aditional_params')

  # Name and path for the statistics to be generated in the trimming process

    outstats1 = File.join(File.expand_path(OUTPUT_PATH),"vectors_trimming_stats.txt")

  # Creates an array to store the necessary fragments to assemble the first call

    cmd_add_add = Array.new

  # Adding invariable fragment

    cmd_add_add.push("bbduk2.sh -Xmx#{max_ram} t=#{cores} k=#{vectors_kmer_size} mink=#{vectors_min_external_kmer_size} hdist=#{vectors_max_mismatches}")

  # Adding necessary fragment to save unpaired singles

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_vectors_trimming.fastq.gz")
    cmd_add_add.push("outs=#{outsingles}") if save_singles

  # Choosing which tips are going to be trimmed

    if vectors_trimming_position == 'both'

      cmd_add_add.push("rref=#{vectors_db} lref=#{vectors_db}")

    elsif vectors_trimming_position == 'right'

      cmd_add_add.push("rref=#{vectors_db}")

    elsif vectors_trimming_position == 'left'

      cmd_add_add.push("lref=#{vectors_db}")

    end

  # Adding necessary info to process paired samples

    if sample_type == "paired" || sample_type == "interleaved"

      cmd_add_add.push("int=t")

    end 
    
  # Adding closing args to the call and joining it

    closing_args = "in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58" 

    cmd_add_add.push(closing_args)

    cmd1 = cmd_add_add.join(" ")

    cmd_add.push(cmd1)

  # Contaminant's Filtering params

    minratio = @params.get_param('vectors_minratio')
    vectors_filtering_aditional_params = @params.get_param('vectors_aditional_params')
    vectors_path = File.join($DB_PATH,'vectors')

  # Name and path for the statistics to be generated in the filtering process

    outstats = File.join(File.expand_path(OUTPUT_PATH),"filtering_vectors_stats.txt")

  # Creates an array to store the fragments

   cmd_add_add = Array.new

  # Adding invariable fragment

   cmd_add_add.push("bbsplit.sh -Xmx#{max_ram} t=#{cores} minratio=#{minratio}")

  # Adding necessary info to process sample as paired

   cmd_add_add.push("int=t") if sample_type = ("paired" || "interleaved")

  # Adding reference and path to the index 

   cmd_add_add.push("ref=#{vectors_db} path=#{vectors_path}")

  # Adding closing args to the call

   if vectors_trimming_aditional_params != 'false'

    cmd_add.push(vectors_aditional_params)

   end

  # Name and path for the statistics to be generated in the filtering process

  outstats2 = File.join(File.expand_path(OUTPUT_PATH),"vectors_filtering_stats.txt")

   closing_args = "in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"
   cmd_add_add.push(closing_args)

  # Assembling the call and adding it to the plugins result

   cmd2 = cmd_add_add.join(" ")
   cmd_add.push(cmd2)

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

    comment='Save reads which became unpaired after every step? true or false (default)'
    default_value = 'false'
    params.check_param(errors,'save_unpaired','String',default_value,comment)

    comment='Trim vectors in which position: right, left or both (default)' 
    default_value = 'both'
    params.check_param(errors,'vectors_trimming_position','String',default_value,comment)

    comment='Sequences of adapters to use in trimming: list of fasta files (comma separated)' 
    default_value = File.join(File.expand_path($DB_PATH),'vectors/vectors.fasta')
    params.check_param(errors,'vectors_db','String',default_value,comment)

    comment='Main kmer size to use in vectors trimming'
    default_value = 31
    params.check_param(errors,'vectors_kmer_size','Integer',default_value,comment)

    comment='Minimal kmer size to use in read tips during vectors trimming'
    default_value = 8
    params.check_param(errors,'vectors_min_external_kmer_size','Integer',default_value,comment)
    
    comment='Max number of mismatches accepted during vectors trimming'
    default_value = 1
    params.check_param(errors,'vectors_max_mismatches','Integer',default_value,comment)
   
    comment='Minimal ratio of vectors kmers in a read to be deleted' 
    default_value = 0.56
    params.check_param(errors,'vectors_minratio','String',default_value,comment)  
    
    comment='Aditional BBsplit parameters for vectors trimming, add them together between quotation marks and separated by one space'
    default_value = 'false'
    params.check_param(errors,'vectors_trimming_aditional_params','String',default_value,comment)

    comment='Trim adapters of paired reads using mergind reads methods for vectors trimming'
    default_value = 'true'
    params.check_param(errors,'vectors_merging_pairs_trimming','String',default_value,comment)

    return errors
  end

end
