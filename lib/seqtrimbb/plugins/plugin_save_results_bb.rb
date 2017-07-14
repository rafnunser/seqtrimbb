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
    outfiles = @params.get_param('outputfiles')
    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')

    outstats = File.join(File.expand_path(OUTPLUGINSTATS),"output_stats.txt")

    cmd_add = Array.new

    cmd_add.push("java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores} minlength=#{minlength} in=stdin.fastq")

    cmd_add.push("int=t") if sample_type == 'paired' || sample_type == "interleaved"

    if !@params.get_param('ext_cmd').nil?
       cmd_add.push("out=stdout.fastq 2> #{outstats}")
    else
     if sample_type == 'paired'
       cmd_add.push("out=#{outfiles[0]}")
       cmd_add.push("out2=#{outfiles[1]} 2> #{outstats}")
     elsif sample_type == 'interleaved' || sample_type == 'single-ended'
       cmd_add.push("out=#{outfiles[0]} 2> #{outstats}")  
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
    # Extracting stats 

    open_stat_file1 = File.open(stat_file1)
    open_stat_file1.each do |line|
     line.chomp!
     if !line.empty? && (line =~ /^Input:/) #Es el encabezado de la tabla o el archivo
         splitted = line.split(/\t/)
         nreads = splitted[1].split(" ") 
         plugin_stats["sequences"]["input_count"] = nreads[0].to_i
     end
    end
    open_stat_file1.close

    open_stat_file2 = File.open(stat_file2)
    open_stat_file2.each do |line|
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
    open_stat_file2.close
    
    plugin_stats["sequences"]["rejected"] = plugin_stats["sequences"]["input_count"].to_i - plugin_stats["sequences"]["output_count"].to_i
    
    return plugin_stats

 end
 
  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]  
    
    comment='Output files'
    default_value = 
    params.check_param(errors,'outputfiles','Array',default_value,comment)

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
