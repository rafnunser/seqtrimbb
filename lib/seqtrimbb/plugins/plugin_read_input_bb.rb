require "plugin"

########################################################
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginReadInputBb < Plugin
  
 def get_cmd

  # General params

    max_ram = @params.get_param('max_ram') 
    cores = @params.get_param('workers')
    sample_type = @params.get_param('sample_type')
    file_format = @params.get_param('file_format')

    outstats = File.join(File.expand_path(OUTPLUGINSTATS),"input_stats.txt")

  # Creates an array to store the fragments to build the call

    cmd_add = Array.new

  # Invariable fragment

    cmd_add.push("reformat.sh -Xmx#{max_ram} t=#{cores}")

  # Adding input info, vital for a proper processing of paired samples

    if sample_type == "interleaved"
    
     file1 = $SAMPLEFILES[0]
    
     cmd_add.push("in=#{file1} int=t")

    elsif sample_type == "single-ended"
    
     file1 = $SAMPLEFILES[0]
    
     cmd_add.push("in=#{file1}")

    elsif sample_type == "paired"
    
     file1 = $SAMPLEFILES[0]
     file2 = $SAMPLEFILES[1]
    
     cmd_add.push("in=#{file1} in2=#{file2}")

    end

  # Adding input info, vital for a proper processing of samples in fasta format

    if file_format == "fasta"

     if $SAMPLEQUALS

      if sample_type == "paired"

        qual1 = $SAMPLEQUALS[0]
        qual2 = $SAMPLEQUALS[1]
       
        cmd_add.push("qual=#{qual1} qual1=#{qual2}")

      else
        
        qual1 = $SAMPLEQUALS[0]
        
        cmd_add.push("qual=#{qual1}")
      
      end

     else
     
      cmd_add.push("q=40")
     
     end
    end      

  # Adding closing args and joining the call
     
    cmd_add.push("out=stdout.fastq 2> #{outstats}")

    cmd = cmd_add.join(" ")

    return cmd

 end

 def get_stats

    # DOES NOTHING

    plugin_stats = {}
    plugin_stats["sequences"] = {}

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

    comment='Format of the sample: fastq or fasta'
    default_value = 
    params.check_param(errors,'file_format','String',default_value,comment)

    return errors
  end

end
