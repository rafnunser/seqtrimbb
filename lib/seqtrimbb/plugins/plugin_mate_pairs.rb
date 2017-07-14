require "plugin"

########################################################

#
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginMatePairs < Plugin

  def treat_lmp
    
    cmds = get_cmd

    cmd1 = cmds[0]

    $LOG.info("First CMD of mate pairs treatment: \n#{cmd1}")

    cmd2 = cmds[1]

    $LOG.info("Second CMD of mate pairs treatment: \n#{cmd2}")

    system(cmd1)

    # look for internal errors in  first cmd execution

    cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_adapters_trimming_stats_cmd.txt")
    open_cmd_file = File.open(cmd_file)
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

    system(cmd2)

    # look for internal errors in second cmd execution

    cmd_file = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_extra_cmds.txt")
    open_cmd_file = File.open(cmd_file)
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

    @outfiles.each do |outfile|
     if File.exists?(outfile)
       @params.set_param('inputfiles',@outfiles,"# Original input files value from input options")
     else
       STDERR.puts "Internal error: something went wrong in BBtools execution, checking for #{@outfiles} failed."
       exit -1 
     end
    end

    FileUtils.rm(@outlongmate) if File.exists?(@outlongmate)
    FileUtils.rm(@outunknown) if File.exists?(@outunknown)

  end

  def get_cmd

    ## Array to save individual cmds
    cmd = Array.new
  
    # General Params
    
    max_ram = @params.get_param('max_ram')
    cores = @params.get_param('workers')
    files = @params.get_param('inputfiles')
    sample_type = @params.get_param('sample_type')
    linkers = @params.get_param('linker_literal_seq')
    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')
    write_in_gzip = @params.get_param('write_in_gzip')

    if [nil,'',' '].include?(linkers)
        $LOG.error "PluginMatePairs: linker_literal_seq param is empty."
        exit -1
    end

    # Mate Pairs treatment params
     # Set references
    if File.exists?(@params.get_param('adapters_db')) && File.file?(@params.get_param('adapters_db'))
      adapters_db = @params.get_param('adapters_db')
    else
      if Dir.exists?(@params.get_param('adapters_db'))
         fastas = File.join(@params.get_param('adapters_db'),'*.fasta*')
         adapters_db = Dir[fastas].join(',')
      else
         fastas = File.join($DB_PATH,'fastas',@params.get_param('adapters_db'),'*.fasta*')
         adapters_db = Dir[fastas].join(',')
      end
    end
    adapters_kmer_size = @params.get_param('adapters_kmer_size')
    adapters_min_external_kmer_size = @params.get_param('adapters_min_external_kmer_size')
    adapters_max_mismatches = @params.get_param('adapters_max_mismatches')

    outstats_adapters = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_adapters_trimming_stats.txt")
    outstats1 = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_adapters_trimming_stats_cmd.txt")
    outstats_split = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_splitting_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_splitting_stats_cmd.txt")
    outstats3 = File.join(File.expand_path(OUTPLUGINSTATS),"LMP_extra_cmds.txt")

    @outlongmate = File.join(File.expand_path(OUTPUT_PATH),"longmate.fastq.gz")
    @outunknown = File.join(File.expand_path(OUTPUT_PATH),"unknown.fastq.gz")

    #INPUT
    if sample_type == 'paired'
     file1 = files[0]
     file2 = files[1]
     input_frag = "in=#{file1} in2=#{file2}"
    elsif sample_type == 'interleaved'
     file1 = files[0]
     input_frag = "in=#{file1} int=t"
    end
  
    #Call to split libraries. This step will keep all the reads which maybe LMPs truly
    cmd1 = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} rref=#{adapters_db} lref=#{adapters_db} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches} stats=#{outstats_adapters} #{input_frag} out=stdout.fastq tpe tbo 2> #{outstats1} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} in=stdin.fastq out=stdout.fastq kmask=J k=19 hdist=1 mink=11 hdist2=0 literal=#{linkers} 2> #{outstats3} | java -ea -Xmx#{max_ram} -cp #{classp} jgi.SplitNexteraLMP t=#{cores} int=t in=stdin.fastq out=#{@outlongmate} outu=#{@outunknown} stats=#{outstats_split} 2> #{outstats2}"

   #Pushing cmd instead of making a system call
    cmd.push(cmd1)

    #OUTPUT
    preffix = OUTPUT_PATH
    if write_in_gzip
      suffix = '.fastq.gz'
    else
      suffix = '.fastq'
    end

    if sample_type == 'paired'
     @outfiles = [File.join(OUTPUT_PATH,"untreated_LMPreads_1#{suffix}"),File.join(OUTPUT_PATH,"untreated_LMPreads_2#{suffix}")]
     output_frag = "out=#{@outfiles[0]} out2=#{@outfiles[1]}"
    elsif sample_type == 'interleaved' 
     @outfiles = [File.join(OUTPUT_PATH,"untreated_LMPreads#{suffix}")]
     output_frag = "out=#{@outfiles[0]}"
    end

    #Call for masked linkers trimming
    unkmask = '"JJJJJJJJJJJJ"'

    cmd2 = "cat #{@outlongmate} #{@outunknown} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} int=t in=stdin.fastq.gz #{output_frag} lliteral=#{unkmask} rliteral=#{unkmask} k=19 hdist=1 mink=11 hdist2=0 minlength=50 2> #{outstats3}"
 
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

    # Extracting stats 
    
    open_stat_file1 = File.open(stat_file1)
    open_stat_file1.each do |line|
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
    open_stat_file1.close

    # Extracting stats

    open_stat_file2 = File.open(stat_file2)
    open_stat_file2.each do |line|

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
    open_stat_file2.close

    return plugin_stats

 end
 
  def self.check_params(params)

    errors=[]  
   
    comment='Max RAM'
    default_value = 
    params.check_param(errors,'max_ram','String',default_value,comment)

    comment='Number of Threads'
    default_value = 
    params.check_param(errors,'workers','String',default_value,comment)

    comment='Write in gzip?'
    default_value = 
    params.check_param(errors,'write_in_gzip','String',default_value,comment)

    comment='Input files'
    default_value = 
    params.check_param(errors,'inputfiles','Array',default_value,comment)

    comment='Type of sample: paired, single-ended or interleaved.'
    default_value = 
    params.check_param(errors,'sample_type','String',default_value,comment)

    comment='Sequences of adapters to use in trimming' 
    default_value = 'adapters'
    params.check_param(errors,'adapters_db','String',default_value,comment)

    comment= 'Literal sequence of linker to use in masking' 
    default_value = nil
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