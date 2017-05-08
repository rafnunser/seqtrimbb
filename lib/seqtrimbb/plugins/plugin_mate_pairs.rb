require "plugin"

########################################################

#
# Defines the main methods that are necessary to execute Plugin
# Inherit: Plugin
########################################################

class PluginMatePairs < Plugin

  def initialize(params)

    PluginMatePairs.check_params(params)
  
    # General Params

    max_ram = params.get_param('max_ram')
    cores = params.get_param('workers')
    sample_type = params.get_param('sample_type')
    linkers = params.get_param('linker_literal_seq')

    adapters_db = params.get_param('adapters_db')
    adapters_kmer_size = params.get_param('adapters_kmer_size')
    adapters_min_external_kmer_size = params.get_param('adapters_min_external_kmer_size')
    adapters_max_mismatches = params.get_param('adapters_max_mismatches')

    outstats_adapters = File.join(File.expand_path(OUTPUT_PATH),"LMP_adapters_trimmings_stats.txt")
    outstats_linkers = File.join(File.expand_path(OUTPUT_PATH),"LMP_linker_masking_stats.txt")

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

    cmd1 = "bbduk2.sh -Xmx#{max_ram} t=#{cores} rref=#{adapters_db} lref=#{adapters_db} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches} stats=#{outstats_adapters} #{input_frag} out=stdout.fastq tpe tbo | bbduk2.sh -Xmx#{max_ram} t=#{cores} in=stdin.fastq out=stdout.fastq kmask=J k=19 hdist=1 mink=11 hdist2=0 literal=#{linkers} stats=#{outstats_linkers} | splitnextera.sh -Xmx#{max_ram} t=#{cores} int=t in=stdin.fastq out=#{outlongmate} outu=#{outunknown}"

    system(cmd1)

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

    cmd2 = "cat #{outlongmate} #{outunknown} | bbduk2.sh -Xmx#{max_ram} t=#{cores} int=t in=stdin.fastq.gz #{output_frag} lliteral=#{unkmask} rliteral=#{unkmask} k=19 hdist=1 mink=11 hdist2=0 minlength=50"
 
    system(cmd2)

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