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
    ext_cmd=@params.get_param('ext_cmd')

    outstats = File.join(File.expand_path(OUTPLUGINSTATS),"output_stats.txt")

    output = File.expand_path(OUTPUT_PATH)

    cmd_add = Array.new

    cmd_add.push("reformat.sh -Xmx#{max_ram} t=#{cores} minlength=#{minlength} in=stdin.fastq")

    if ext_cmd != nil

     if sample_type == 'paired' || sample_type == "interleaved"

       cmd_add.push("int=t")

       cmd_add.push("out=stdout.fastq 2> #{outstats}")

     else

       cmd_add.push("out=stdout.fastq 2> #{outstats}")

     end

    else
    
     if sample_type == 'paired'

       cmd_add.push("int=t")

       file1 = $OUTPUTFILES[0]
       file2 = $OUTPUTFILES[1]

       cmd_add.push("out=#{output}/#{file1}")
       cmd_add.push("out2=#{output}/#{file2} 2> #{outstats}")

     elsif sample_type == 'interleaved'

       cmd_add.push("int=t")

       file1 = $OUTPUTFILES[0]

       cmd_add.push("out=#{output}/#{file1} 2> #{outstats}")

     else

       file1 = $OUTPUTFILES[0]

       cmd_add.push("out=#{output}/#{file1} 2> #{outstats}") 

     end

    end

    cmd = cmd_add.join(" ")   

    return cmd

 end

 def get_stats

    plugin_stats = {}
    plugin_stats["sequences"] = {}

    stat_file2 = File.join(File.expand_path(OUTPLUGINSTATS),"output_stats.txt")
    stat_file1 = File.join(File.expand_path(OUTPLUGINSTATS),"input_stats.txt")

    # First look for internal errors in cmd execution

     cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"output_stats.txt")

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

    File.open(stat_file1).each do |line|

      line.chomp!

     if !line.empty? && (line =~ /^Input:/) #Es el encabezado de la tabla o el archivo

         splitted = line.split(/\t/)

         nreads = splitted[1].split(" ") 

         plugin_stats["sequences"]["input_count"] = nreads[0].to_i

     end

    end

    File.open(stat_file2).each do |line|

      line.chomp!

     if !line.empty? && (line =~ /^Output:/) #Es el encabezado de la tabla o el archivo

         splitted = line.split(/\t/)

         nreads = splitted[1].split(" ")

         plugin_stats["sequences"]["output_count"] = nreads[0].to_i

     elsif !line.empty? && (line =~ /^Short/)

         splitted = line.split(/\t/)

         nreads = splitted[1].split(" ")

         plugin_stats["sequences"]["final_short_reads_discards"] = nreads[0].to_i
     end


    end

    plugin_stats["sequences"]["rejected"] = plugin_stats["sequences"]["input_count"].to_i - plugin_stats["sequences"]["output_count"].to_i
    
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
  
    comment='Minimal reads length to be keep' 
    default_value = '50'
    params.check_param(errors,'minlength','String',default_value,comment)

    comment='External cmd to pipe' 
    default_value = nil
    params.check_param(errors,'ext_cmd','String',default_value,comment)

    return errors
  end

end
