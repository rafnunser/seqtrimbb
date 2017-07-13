require "plugin"

########################################################
# 
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginQuality < Plugin
  
 def get_cmd

  # General params
    max_ram = @params.get_param('max_ram')
    cores = @params.get_param('workers')
    sample_type = @params.get_param('sample_type')
    write_in_gzip = @params.get_param('write_in_gzip')
    save_singles = @params.get_param('save_unpaired')
    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')
    
  # Quality's trimming params
    quality_threshold = @params.get_param('quality_threshold')
    quality_trimming_position = @params.get_param('quality_trimming_position')
    quality_aditional_params = @params.get_param('quality_aditional_params')
    outstats = File.join(File.expand_path(OUTPLUGINSTATS),"quality_trimming_stats.txt")

  # Creates an array to store the necessary fragments to assemble the call
    cmd_add = Array.new

  # Adding invariable fragment
    cmd_add.push("java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} trimq=#{quality_threshold}")
   
  # Adding necessary fragment to save unpaired singles
    if write_in_gzip   
        suffix = 'fastq.gz'
    else
         suffix = 'fastq'
    end
    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_quality_trimming.#{suffix}")
    cmd_add.push("outs=#{outsingles}") if save_singles == 'true'
 
 # Choosing which tips are going to be trimmed
    if quality_trimming_position == 'both'
      cmd_add.push("qtrim=rl")
    elsif quality_trimming_position == 'right'
      cmd_add.push("qtrim=r")
    elsif quality_trimming_position == 'left'
      cmd_add.push("qtrim=l")
    end

   # Adding necessary info to process paired samples
    if sample_type == "paired" || sample_type == "interleaved"
      cmd_add.push("int=t")
    end 
    
    # Adding closing args to the call and joining it
    if !quality_aditional_params.nil?
      cmd_add.push(quality_aditional_params)
    end

    closing_args = "in=stdin.fastq out=stdout.fastq 2> #{outstats}" 

    cmd_add.push(closing_args)

    cmd = cmd_add.join(" ")

    return cmd

 end

 def get_stats

    plugin_stats = {}
    plugin_stats["plugin_quality"] = {}

    stat_file = File.join(File.expand_path(OUTPLUGINSTATS),"quality_trimming_stats.txt")

    # First look for internal errors in cmd execution
     cmd_file = stat_file

     File.open(cmd_file).each do |line|
      line.chomp!
      if !line.empty?
        if (line =~ /Exception in thread/) || (line =~ /Error/)
           STDERR.puts "Internal error in BBtools execution. For more details: #{cmd_file}"
           exit -1 
        end
      end
     end

    # Extracting stats 
    File.open(stat_file).each do |line|
      line.chomp!
     if !line.empty? && (line =~ /^QTrimmed:/) #Es el encabezado de la tabla o el archivo
         splitted = line.split(/\t/)
         nreads = splitted[1].split(" ")
         nbases = splitted[2].split(" ")
         plugin_stats["plugin_quality"]["quality_trimmed_reads"] = nreads[0].to_i
         plugin_stats["plugin_quality"]["quality_trimmed_bases"] = nbases[0].to_i
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
    default_value = 
    params.check_param(errors,'workers','String',default_value,comment)

    comment='Type of sample: paired, single-ended or interleaved.'
    default_value = 
    params.check_param(errors,'sample_type','String',default_value,comment)

    comment='Write in gzip?'
    default_value = 
    params.check_param(errors,'write_in_gzip','String',default_value,comment)

    comment='Save reads which became unpaired after every step? true or false (default)'
    default_value = 'false'
    params.check_param(errors,'save_unpaired','String',default_value,comment)

    comment='Quality threshold to be applied (Phred quality score)' 
    default_value = '20'
    params.check_param(errors,'quality_threshold','String',default_value,comment)

    comment='Trim bad quality bases in which position: right, left or both (default)' 
    default_value = 'both'
    params.check_param(errors,'quality_trimming_position','String',default_value,comment)

    comment='Aditional BBduk2 parameters, add them together between quotation marks and separated by one space'
    default_value = nil
    params.check_param(errors,'quality_aditional_params','String',default_value,comment)

    return errors
  end

end
