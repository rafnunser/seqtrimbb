require "plugin"

########################################################
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginAdapters < Plugin
  
 def get_cmd

  # General params

    max_ram = @params.get_param('max_ram')
    cores = @params.get_param('workers')
    sample_type = @params.get_param('sample_type')
    save_singles = @params.get_param('save_unpaired')

  # Adapters trimming params

    adapters_db = @params.get_param('adapters_db')
    adapters_trimming_position = @params.get_param('adapters_trimming_position')
    adapters_kmer_size = @params.get_param('adapters_kmer_size')
    adapters_min_external_kmer_size = @params.get_param('adapters_min_external_kmer_size')
    adapters_max_mismatches = @params.get_param('adapters_max_mismatches')
    adapters_aditional_params = @params.get_param('adapters_aditional_params')
    adapters_merging_pairs_trimming = @params.get_param('adapters_merging_pairs_trimming')

  # Name and path for the statistics to be generated in the trimming process

    outstats = File.join(File.expand_path(OUTPLUGINSTATS),"adapters_trimmings_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"adapters_trimmings_stats_cmd.txt")

  # Creates an array to store the necessary fragments to assemble the call

    cmd_add = Array.new

  # Adding invariable fragment

    cmd_add.push("bbduk2.sh -Xmx#{max_ram} t=#{cores} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches}")

  # Adding necessary fragment to save unpaired singles

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_adapters_trimming.fastq.gz")
    cmd_add.push("outs=#{outsingles}") if save_singles == 'true'

  # Choosing which tips are going to be trimmed

    if adapters_trimming_position == 'both'

      cmd_add.push("rref=#{adapters_db} lref=#{adapters_db}")

    elsif adapters_trimming_position == 'right'

      cmd_add.push("rref=#{adapters_db}")

    elsif adapters_trimming_position == 'left'

      cmd_add.push("lref=#{adapters_db}")

    end

  # Adding necessary info to process paired samples

    if sample_type == "paired" || sample_type == "interleaved"

      cmd_add.push("int=t")
      cmd_add.push("tbo tpe") if adapters_merging_pairs_trimming == 'true'

    end 
    
  # Adding closing args to the call and joining it

    if adapters_aditional_params != nil

      cmd_add.push(adapters_aditional_params)

    end

    closing_args = "in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}" 

    cmd_add.push(closing_args)

    cmd = cmd_add.join(" ")

    return cmd

 end

 def get_stats

    plugin_stats = {}
    plugin_stats["plugin_adapters"] = {}
    plugin_stats["plugin_adapters"]["sequences_with_adapter"] = {}
    plugin_stats["plugin_adapters"]["adapter_id"] = {}

    stat_file = File.join(File.expand_path(OUTPLUGINSTATS),"adapters_trimmings_stats.txt")

    File.open(stat_file).each do |line|

      line.chomp!

     if !line.empty?

       if (line =~ /^\s*#/) #Es el encabezado de la tabla o el archivo
    
         line[0]=''

         splitted = line.split(/\t/)

         plugin_stats["plugin_adapters"]["sequences_with_adapter"]["count"] = splitted[1].to_i if splitted[0] == 'Matched'

       else 

         splitted = line.split(/\t/)
         
         plugin_stats["plugin_adapters"]["adapter_id"][splitted[0]] = splitted[1].to_i

       end
     end
    end

    return plugin_stats

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

    comment='Trim adapters in which position: right, left or both (default)' 
    default_value = 'both'
    params.check_param(errors,'adapters_trimming_position','String',default_value,comment)

    comment='Sequences of adapters to use in trimming' 
    default_value = File.join($DB_PATH,'adapters/adapters.fasta')
    params.check_param(errors,'adapters_db','String',default_value,comment)

    comment='Main kmer size to use in adapters trimming'
    default_value = 15
    params.check_param(errors,'adapters_kmer_size','Integer',default_value,comment)

    comment='Minimal kmer size to use in read tips during adapters trimming'
    default_value = 8
    params.check_param(errors,'adapters_min_external_kmer_size','Integer',default_value,comment)
    
    comment='Max number of mismatches accepted during adapters trimming'
    default_value = 1
    params.check_param(errors,'adapters_max_mismatches','Integer',default_value,comment)

    comment='Aditional BBduk2 parameters, add them together between quotation marks and separated by one space'
    default_value = nil
    params.check_param(errors,'adapters_aditional_params','String',default_value,comment)

    comment='Trim adapters of paired reads using mergind reads methods'
    default_value = 'true'
    params.check_param(errors,'adapters_merging_pairs_trimming','String',default_value,comment)

    return errors
  end

end
