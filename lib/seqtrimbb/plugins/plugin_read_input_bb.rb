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
    files = @params.get_param('inputfiles')
    quals = @params.get_param('inputqualfiles')
    sample_type = @params.get_param('sample_type')
    file_format = @params.get_param('file_format')

    outstats = File.join(File.expand_path(OUTPLUGINSTATS),"input_stats.txt")

    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')

  # Creates an array to store the fragments to build the call

    cmd_add = Array.new

  # Invariable fragment

    cmd_add.push("java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores}")

  # Adding input info, vital for a proper processing of paired samples

    if sample_type == "interleaved"
      file1 = files[0]
      cmd_add.push("in=#{file1} int=t")
    elsif sample_type == "single-ended"
      file1 = files[0]
      cmd_add.push("in=#{file1}")
    elsif sample_type == "paired"
      file1 = files[0]
      file2 = files[1]
      cmd_add.push("in=#{file1} in2=#{file2}")
    end

  # Adding input info, vital for a proper processing of samples in fasta format

    if file_format == "fasta"
     if !quals.nil?
      if sample_type == "paired"
        qual1 = quals[0]
        qual2 = quals[1]
        cmd_add.push("qfin=#{qual1} qfin2=#{qual2}")
      else
        qual1 = quals[0]
        cmd_add.push("qfin=#{qual1}")
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

    # First look for internal errors in cmd execution

    cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"input_stats.txt")
    open_cmd_file= File.open(cmd_file)
    open_cmd_file.each do |line|
      line.chomp!
      if !line.empty?
        if (line =~ /Exception in thread/) || (line =~ /Error/)
           STDERR.puts "Internal error in BBtools execution. For more details: #{cmd_file}"
           exit -1 
        end
      end
    end
    open_cmd_file.close

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
    default_value = 
    params.check_param(errors,'workers','String',default_value,comment)

    comment='Input files'
    default_value = 
    params.check_param(errors,'inputfiles','Array',default_value,comment)

    comment='Qual files'
    default_value = 
    params.check_param(errors,'qualfiles','Array',default_value,comment)    

    comment='Type of sample: paired, single-ended or interleaved.'
    default_value = 
    params.check_param(errors,'sample_type','String',default_value,comment)

    comment='Format of the sample: fastq or fasta'
    default_value = 
    params.check_param(errors,'file_format','String',default_value,comment)

    return errors
  end

end
