require "plugin"

########################################################

#
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginMatePairs < Plugin

  def treat_lmp(params)

    PluginMatePairs.check_params(params)
    
    cmds = PluginMatePairs.get_cmd(params)

    cmd1 = cmds[0]

    $LOG.info("First CMD of mate pairs treatment: \n#{cmd1}")

    cmd2 = cmds[1]

    $LOG.info("Second CMD of mate pairs treatment: \n#{cmd2}")

    system(cmd1)
    system(cmd2)

  end

  def self.get_cmd(params)

    PluginMatePairs.check_params(params)

    ## Array to save individual cmds

    cmd = Array.new
  
    # General Params

    max_ram = params.get_param('max_ram')
    cores = params.get_param('workers')
    sample_type = params.get_param('sample_type')
    linkers = params.get_param('linker_literal_seq')

    adapters_db = params.get_param('adapters_db')
    adapters_kmer_size = params.get_param('adapters_kmer_size')
    adapters_min_external_kmer_size = params.get_param('adapters_min_external_kmer_size')
    adapters_max_mismatches = params.get_param('adapters_max_mismatches')

    outstats_adapters = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_adapters_trimming_stats.txt")
    outstats1 = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_adapters_trimming_stats_cmd.txt")
    outstats_split = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_splitting_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_splitting_stats_cmd.txt")
    outstats3 = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_extra_cmds.txt")

    outlongmate = File.join(File.expand_path(OUTPUT_PATH),"longmate.fastq.gz")
    outunknown = File.join(File.expand_path(OUTPUT_PATH),"unknown.fastq.gz")


    #INPUT

    if sample_type == 'paired'

     file1 = $SAMPLEFILES[0]
     file2 = $SAMPLEFILES[1]
    
     input_frag = "in=#{file1} in2=#{file2}"
    
    elsif sample_type == 'interleaved'
      
     file1 = $SAMPLEFILES[0]
    
     input_frag = "in=#{file1} int=t"

    end
  
    #Call to split libraries. This step will keep all the reads which maybe LMPs truly

    cmd1 = "bbduk2.sh -Xmx#{max_ram} t=#{cores} rref=#{adapters_db} lref=#{adapters_db} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches} stats=#{outstats_adapters} #{input_frag} out=stdout.fastq tpe tbo 2> #{outstats1} | bbduk2.sh -Xmx#{max_ram} t=#{cores} in=stdin.fastq out=stdout.fastq kmask=J k=19 hdist=1 mink=11 hdist2=0 literal=#{linkers} 2> #{outstats3} | splitnextera.sh -Xmx#{max_ram} t=#{cores} int=t in=stdin.fastq out=#{outlongmate} outu=#{outunknown} stats=#{outstats_split} 2> #{outstats2}"

   #Pushing cmd instead of making a system call

    cmd.push(cmd1)

    #OUTPUT

    if sample_type == 'paired'

     output_frag = "out=untreated_LMPreads_1.fastq.gz out2=untreated_LMPreads_2.fastq.gz"

     $SAMPLEFILES[0] = "untreated_LMPreads_1.fastq.gz"
     $SAMPLEFILES[1] = "untreated_LMPreads_2.fastq.gz"
     
    elsif sample_type == 'interleaved'
      
     output_frag = "out=untreated_LMPreads.fastq.gz"

     $SAMPLEFILES[0] = "untreated_LMPreads.fastq.gz"

    end

    #Call for masked linkers trimming

    unkmask = '"JJJJJJJJJJJJ"'

    cmd2 = "cat #{outlongmate} #{outunknown} | bbduk2.sh -Xmx#{max_ram} t=#{cores} int=t in=stdin.fastq.gz #{output_frag} lliteral=#{unkmask} rliteral=#{unkmask} k=19 hdist=1 mink=11 hdist2=0 minlength=50 2> #{outstats3}"
 
   #Pushing cmd instead of making a system call

    cmd.push(cmd2)

    return cmd

  end

 def get_stats

    plugin_stats = {}
    plugin_stats["plugin_adapters"] = {}
    plugin_stats["plugin_adapters"]["sequences_with_adapter"] = {}
    plugin_stats["plugin_adapters"]["sequences_with_adapter"]["count"] = 0
    plugin_stats["plugin_adapters"]["adapter_id"] = {}
    plugin_stats["plugin_mate_pairs"] = {}
    plugin_stats["plugin_mate_pairs"]["long_mate_pairs"] = {}
    plugin_stats["plugin_mate_pairs"]["long_mate_pairs"]["count"] = 0

    stat_file1 = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_adapters_trimming_stats.txt")
    stat_file2 = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_splitting_stats.txt")

    # First look for internal errors in cmd execution

     cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_adapters_trimming_stats_cmd.txt")

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

     if !line.empty?

       if (line =~ /^\s*#/) #Es el encabezado de la tabla o el archivo
    
         line[0]=''

         splitted = line.split(/\t/)

         plugin_stats["plugin_adapters"]["sequences_with_adapter"]["count"] = splitted[1].to_i if splitted[0] == 'Matched'

       else 

         splitted = line.split(/\t/)
         
         plugin_stats["plugin_adapters"]["adapter_id"][splitted[0]] = splitted[1]

       end
     end
    end

    # First look for internal errors in cmd execution

     cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_extra_cmds.txt")

     File.open(cmd_file).each do |line|

      line.chomp!

      if !line.empty

        if (line =~ /Exception in thread/)

           STDERR.puts "Internal error in BBtools execution. For more details: #{cmd_file}"
           exit -1 
        end
      end
     end

    # Extracting stats

    File.open(stat_file2).each do |line|

      line.chomp!

     if !line.empty?

       if (line =~ /^Long/) #Es el encabezado de la tabla o el archivo

         splitted = line.split(/\t/)

         nreads = splitted[1].split(" ").pop 

         plugin_stats["plugin_mate_pairs"]["long_mate_pairs"]["count"] += nreads.to_i
         plugin_stats["plugin_mate_pairs"]["long_mate_pairs"]["known"] = nreads.to_i

       elsif (line =~ /^Unknown/)

         splitted = line.split(/\t/)
         
         nreads = splitted[1].split(" ").pop 

         plugin_stats["plugin_mate_pairs"]["long_mate_pairs"]["count"] += nreads.to_i
         plugin_stats["plugin_mate_pairs"]["long_mate_pairs"]["unknown"] = nreads.to_i

       elsif (line =~ /^Adapters/)

         splitted = line.split(/\t/)
         
         plugin_stats["plugin_mate_pairs"]["linkers_detected"]= splitted[1]

       end
     end
    end

    return plugin_stats

 end
 
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

    comment='Sequences of adapters to use in trimming' 
    default_value = File.join($DB_PATH,'adapters/adapters.fasta')
    params.check_param(errors,'adapters_db','String',default_value,comment)

    comment= 'Literal sequence of linker to use in masking' 
    default_value = 
    params.check_param(errors,'linker_literal_seq','String',default_value,comment)

    comment='Main kmer size to use in adapters trimming'
    default_value = 15
    params.check_param(errors,'adapters_kmer_size','Integer',default_value,comment)

    comment='Minimal kmer size to use in read tips during adapters trimming'
    default_value = 8
    params.check_param(errors,'adapters_min_external_kmer_size','Integer',default_value,comment)
    
    comment='Max number of mismatches accepted during adapters trimming'
    default_value = 1
    params.check_param(errors,'adapters_max_mismatches','Integer',default_value,comment)

    return errors
  end

end