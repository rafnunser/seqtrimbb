require "plugin"

########################################################
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginSaveResultsBb < Plugin
  
 def get_cmd
    
    max_ram = @params.get_param('max_ram')
    cores = @params.get_param('workers')
    sample_type = @params.get_param('sample_type')
    minlength = @params.get_param('minlength')

    output = File.expand_path(DEFAULT_FINAL_OUTPUT_PATH)

    cmd_add = Array.new

    cmd_add.push("reformat.sh -Xmx#{max_ram} t=#{cores} minlength=#{minlength} in=stdin.fastq")

    
    if sample_type == 'paired'

       cmd_add.push("int=t")

       file1 = $OUTPUTFILES[0]
       file2 = $OUTPUTFILES[1]

       cmd_add.push("out=#{output}/#{file1}")
       cmd_add.push("out2=#{output}/#{file2}")

    elsif sample_type == 'interleaved'

       cmd_add.push("int=t")

       file1 = $OUTPUTFILES[0]

       cmd_add.push("out=#{output}/#{file1}")

    else

       file1 = $OUTPUTFILES[0]

       cmd_add.push("out=#{output}/#{file1}") 

    end

    cmd = cmd_add.join(" ")   

    return cmd

 end
 
  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]  
    
    comment='Save results in a compressed file'
    default_value = 'true'
    params.check_param(errors,'save_results_bb_save_in_gzip','String',default_value,comment)
    
    comment='Max RAM'
    default_value = 
    params.check_param(errors,'max_ram','String',default_value,comment)

    comment='Number of Threads'
    default_value = 1
    params.check_param(errors,'workers','String',default_value,comment)

    comment='Type of sample: paired, single-ended or interleaved.'
    default_value = 
    params.check_param(errors,'sample_type','String',default_value,comment)
  
    comment='Minimal reads length to be keep' 
    default_value = '50'
    params.check_param(errors,'minlength','String',default_value,comment)

    return errors
  end

end
