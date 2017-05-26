require "plugin"

########################################################
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginLowComplexity < Plugin
  
 def get_cmd

  # General params

    max_ram = @params.get_param('max_ram')
    cores = @params.get_param('workers')
    sample_type = @params.get_param('sample_type')
    save_singles = @params.get_param('save_unpaired')

  # Adapter's trimming params

    entropy_threshold = @params.get_param('complexity_threshold')
    lowcomplexity_aditional_params = @params.get_param('low_complexity_aditional_params')
    minlength = @params.get_param('minlength')
    outstats = File.join(File.expand_path(OUTPLUGINSTATS),"low_complexity_stats.txt")


    if minlength.to_i < 50

      entropy_window = minlength

    else

      entropy_window = 50

    end
  # Creates an array to store the necessary fragments to assemble the call

    cmd_add = Array.new

  # Adding invariable fragment

    cmd_add.push("bbduk2.sh -Xmx#{max_ram} t=#{cores} entropy=#{entropy_threshold} entropywindow=#{entropy_window}")
   
  # Adding necessary fragment to save unpaired singles

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_low_complexity_filtering.fastq.gz")
    cmd_add.push("outs=#{outsingles}") if save_singles == 'true'

  # Adding necessary info to process paired samples

    if sample_type == "paired" || sample_type == "interleaved"

      cmd_add.push("int=t")

    end 

  # Adding closing args to the call and joining it

    if lowcomplexity_aditional_params != nil

      cmd_add.push(lowcomplexity_aditional_params)

    end

    closing_args = "in=stdin.fastq out=stdout.fastq 2> #{outstats}" 

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
    default_value = 
    params.check_param(errors,'workers','String',default_value,comment)

    comment='Type of sample: paired, single-ended or interleaved.'
    default_value = 
    params.check_param(errors,'sample_type','String',default_value,comment)

    comment='Save reads which became unpaired after every step? true or false (default)'
    default_value = 'false'
    params.check_param(errors,'save_unpaired','String',default_value,comment)

    comment='Complexity threshold to be applied. Complexity is calculated using the counts of unique short kmers that occur in a window, such that the more unique kmers occur within the window - and the more even the distribution of counts - the closer the value approaches 1. Complexity_threshold = 0.01 for example will only filter homopolymers' 
    default_value = '0.01'
    params.check_param(errors,'complexity_threshold','String',default_value,comment)

    comment='Minimal reads length to be keep' 
    default_value = '50'
    params.check_param(errors,'minlength','String',default_value,comment)

    comment='Aditional BBduk2 parameters, add them together between quotation marks and separated by one space'
    default_value = nil
    params.check_param(errors,'lowcomplexity_aditional_params','String',default_value,comment)

    return errors
  end

end
