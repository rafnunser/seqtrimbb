require 'test_helper'

class PluginMatePairsTest < Minitest::Test

  def test_plugin_mate_pairs

    require 'plugin_mate_pairs.rb'

    options = {}

    linker = 'AGCTTCGAAGCTTCGA'

    options['max_ram'] = '1G'
    options['cores'] = '1'
    options['sample_type'] = 'paired'
    options['linker_literal_seq'] = 'AGCTTCGAAGCTTCGA' 

    adapters_db = File.join($DB_PATH,'adapters/adapters.fasta')
    outstats_adapters = File.join(File.expand_path(OUTPUT_PATH),"LMP_adapters_trimmings_stats.txt")
    outstats_linkers = File.join(File.expand_path(OUTPUT_PATH),"LMP_linker_masking_stats.txt")

    options['adapters_db'] = adapters_db
    options['adapters_kmer_size'] = 15
    options['adapters_min_external_kmer_size'] = 8
    options['adapters_max_mismatches'] = 1

    outlongmate = File.join(File.expand_path(OUTPUT_PATH),"longmate.fastq.gz")
    outunknown = File.join(File.expand_path(OUTPUT_PATH),"unknown.fastq.gz")

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    params = Params.new(faketemplate,options)

# Paired sample

   file1 = "testfile_1.fastq"
   file2 = "testfile_2.fastq"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file1
   $SAMPLEFILES[1] = file2

   input_frag = "in=#{file1} in2=#{file2}"

   unkmask = '"JJJJJJJJJJJJ"'

   output_frag = "out=untreated_LMPreads_1.fastq.gz out2=untreated_LMPreads_2.fastq.gz"

   result = Array.new

   result.push("bbduk2.sh -Xmx1G t=1 rref=#{adapters_db} lref=#{adapters_db} k=15 mink=8 hdist=1 stats=#{outstats_adapters} #{input_frag} out=stdout.fastq tpe tbo | bbduk2.sh -Xmx1G t=1 in=stdin.fastq out=stdout.fastq kmask=J k=19 hdist=1 mink=11 hdist2=0 literal=#{linker} stats=#{outstats_linkers} | splitnextera.sh -Xmx1G t=1 int=t in=stdin.fastq out=#{outlongmate} outu=#{outunknown}")
   result.push("cat #{outlongmate} #{outunknown} | bbduk2.sh -Xmx1G t=1 int=t in=stdin.fastq.gz #{output_frag} lliteral=#{unkmask} rliteral=#{unkmask} k=19 hdist=1 mink=11 hdist2=0 minlength=50")
   
   test = PluginMatePairs.get_cmd(params)

   assert_equal(result,test)

# Interleaved sample

   options['sample_type'] = 'interleaved'

   params = Params.new(faketemplate,options)

   file1 = "testfile_1.fastq"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file1

   input_frag = "in=#{file1}"

   unkmask = '"JJJJJJJJJJJJ"'

   output_frag = "out=untreated_LMPreads.fastq.gz"

   result = Array.new

   result.push("bbduk2.sh -Xmx1G t=1 rref=#{adapters_db} lref=#{adapters_db} k=15 mink=8 hdist=1 stats=#{outstats_adapters} #{input_frag} int=t out=stdout.fastq tpe tbo | bbduk2.sh -Xmx1G t=1 in=stdin.fastq out=stdout.fastq kmask=J k=19 hdist=1 mink=11 hdist2=0 literal=#{linker} stats=#{outstats_linkers} | splitnextera.sh -Xmx1G t=1 int=t in=stdin.fastq out=#{outlongmate} outu=#{outunknown}")
   result.push("cat #{outlongmate} #{outunknown} | bbduk2.sh -Xmx1G t=1 int=t in=stdin.fastq.gz #{output_frag} lliteral=#{unkmask} rliteral=#{unkmask} k=19 hdist=1 mink=11 hdist2=0 minlength=50")
   
   test = PluginMatePairs.get_cmd(params)

   assert_equal(result,test)

  end

end
