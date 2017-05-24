require "plugin"

########################################################
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginPolyAT < Plugin
  
 def get_cmd

  # General params

    max_ram = @params.get_param('max_ram')
    cores = @params.get_param('workers')
    sample_type = @params.get_param('sample_type')
    save_singles = @params.get_param('save_unpaired')

  # Adapters trimming params

    polyat_trimming_position = @params.get_param('polyat_trimming_position')
    polyat_kmer_size = @params.get_param('polyat_kmer_size')
    polyat_min_external_kmer_size = @params.get_param('polyat_min_external_kmer_size')
    polyat_max_mismatches = @params.get_param('polyat_max_mismatches')
    polyat_aditional_params = @params.get_param('polyat_aditional_params')

  # Name and path for the statistics to be generated in the trimming process

    outstats = File.join(File.expand_path(OUTPUT_PATH),"polyat_trimmings_stats.txt")

  # Creates an array to store the necessary fragments to assemble the call

    cmd_add = Array.new

  # Adding invariable fragment

    cmd_add.push("bbduk2.sh -Xmx#{max_ram} t=#{cores} k=#{polyat_kmer_size} mink=#{polyat_min_external_kmer_size} hdist=#{polyat_max_mismatches}")

  # Adding necessary fragment to save unpaired singles

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_polyat_trimming.fastq.gz")
    cmd_add.push("outs=#{outsingles}") if save_singles

  # Choosing which tips are going to be trimmed

    if polyat_trimming_position == 'both'

      cmd_add.push("rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")

    elsif polyat_trimming_position == 'right'

      cmd_add.push("rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")

    elsif polyat_trimming_position == 'left'

      cmd_add.push("lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")

    end

  # Adding necessary info to process paired samples

    if sample_type == "paired" || sample_type == "interleaved"

      cmd_add.push("int=t")

    end 
    
  # Adding closing args to the call and joining it

    if polyat_aditional_params != 'false'

      cmd_add.push(polyat_aditional_params)

    end

    closing_args = "in=stdin.fastq out=stdout.fastq stats=#{outstats}" 

    cmd_add.push(closing_args)

    cmd = cmd_add.join(" ")

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

    comment='Trim PolyAT in which position: right, left or both (default)' 
    default_value = 'both'
    params.check_param(errors,'polyat_trimming_position','String',default_value,comment)

    comment='Main kmer size to use in PolyAT trimming'
    default_value = 31
    params.check_param(errors,'polyat_kmer_size','Integer',default_value,comment)

    comment='Minimal kmer size to use in read tips during PolyAT trimming'
    default_value = 9
    params.check_param(errors,'polyat_min_external_kmer_size','Integer',default_value,comment)
    
    comment='Max number of mismatches accepted during PolyAT trimming'
    default_value = 1
    params.check_param(errors,'polyat_max_mismatches','Integer',default_value,comment)

    comment='Aditional BBduk2 parameters, add them together between quotation marks and separated by one space'
    default_value = 'false'
    params.check_param(errors,'polyat_aditional_params','String',default_value,comment)

    return errors
  end

end
