require 'test_helper'

class PluginMatePairsTest < Minitest::Test

  def test_plugin_mate_pairs

    require 'plugin_mate_pairs.rb'
    plugin_name = 'PluginMatePairs'

    options = {}

    linker = 'AGCTTCGAAGCTTCGA'

    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')
    max_ram = '1g'
    cores = '1'
    sample_type = 'paired'
    file1 = File.join(RT_PATH,"DB","testfiles","testfile_1.fastq.gz")
    file2 = File.join(RT_PATH,"DB","testfiles","testfile_2.fastq.gz")

    options['file'] = [file1,file2]
    options['max_ram'] = max_ram
    options['workers'] = cores
    options['sample_type'] = sample_type
    options['linker_literal_seq'] = 'AGCTTCGAAGCTTCGA' 

    adapters_db = File.join($DB_PATH,'fastas/adapters/adapters.fasta')
    outstats_adapters = File.join(File.expand_path(OUTPUT_PATH),"LMP_adapters_trimming_stats.txt")
    outstats1 = File.join(File.expand_path(OUTPUT_PATH),"LMP_adapters_trimming_stats_cmd.txt")
    outstats_split = File.join(File.expand_path(OUTPUT_PATH),"LMP_splitting_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"LMP_splitting_stats_cmd.txt")
    outstats3 = File.join(File.expand_path(OUTPUT_PATH),"LMP_extra_cmds.txt")

    options['adapters_db'] = 'adapters'
    options['adapters_kmer_size'] = 15
    options['adapters_min_external_kmer_size'] = 8
    options['adapters_max_mismatches'] = 1

    outlongmate = File.join(File.expand_path(OUTPUT_PATH),"longmate.fastq.gz")
    outunknown = File.join(File.expand_path(OUTPUT_PATH),"unknown.fastq.gz")

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    params = Params.new(faketemplate,options)

    suffix = '.fastq'

# Paired sample

   input_frag = "in=#{file1} in2=#{file2}"
   outfiles = [File.join(OUTPUT_PATH,"untreated_LMPreads_1#{suffix}"),File.join(OUTPUT_PATH,"untreated_LMPreads_2#{suffix}")]

   unkmask = '"JJJJJJJJJJJJ"'

   output_frag = "out=#{outfiles[0]} out2=#{outfiles[1]}"

   result = Array.new

   result.push("java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} rref=#{adapters_db} lref=#{adapters_db} k=15 mink=8 hdist=1 stats=#{outstats_adapters} #{input_frag} out=stdout.fastq tpe tbo 2> #{outstats1} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} in=stdin.fastq out=stdout.fastq kmask=J k=19 hdist=1 mink=11 hdist2=0 literal=#{linker} 2> #{outstats3} | java -ea -Xmx#{max_ram} -cp #{classp} jgi.SplitNexteraLMP t=#{cores} int=t in=stdin.fastq out=#{outlongmate} outu=#{outunknown} stats=#{outstats_split} 2> #{outstats2}")
   result.push("cat #{outlongmate} #{outunknown} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} int=t in=stdin.fastq.gz #{output_frag} lliteral=#{unkmask} rliteral=#{unkmask} k=19 hdist=1 mink=11 hdist2=0 minlength=50 2> #{outstats3}")
   
   plugin_class = Object.const_get(plugin_name)
   p = plugin_class.new(params)
   test = p.get_cmd

   assert_equal(result,test)

# Interleaved sample

   file1 = File.join(RT_PATH,"DB","testfiles","testfile_interleaved.fastq.gz")
   outfiles = [File.join(OUTPUT_PATH,"untreated_LMPreads#{suffix}")]

   options['file'] = [file1]

   options['sample_type'] = 'interleaved'

   params = Params.new(faketemplate,options)

   input_frag = "in=#{file1} int=t"

   unkmask = '"JJJJJJJJJJJJ"'

   output_frag = "out=#{outfiles[0]}"

   result = Array.new

   result.push("java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} rref=#{adapters_db} lref=#{adapters_db} k=15 mink=8 hdist=1 stats=#{outstats_adapters} #{input_frag} out=stdout.fastq tpe tbo 2> #{outstats1} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} in=stdin.fastq out=stdout.fastq kmask=J k=19 hdist=1 mink=11 hdist2=0 literal=#{linker} 2> #{outstats3} | java -ea -Xmx#{max_ram} -cp #{classp} jgi.SplitNexteraLMP t=#{cores} int=t in=stdin.fastq out=#{outlongmate} outu=#{outunknown} stats=#{outstats_split} 2> #{outstats2}")
   result.push("cat #{outlongmate} #{outunknown} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} int=t in=stdin.fastq.gz #{output_frag} lliteral=#{unkmask} rliteral=#{unkmask} k=19 hdist=1 mink=11 hdist2=0 minlength=50 2> #{outstats3}")
   
   plugin_class = Object.const_get(plugin_name)
   p = plugin_class.new(params)
   test = p.get_cmd

   assert_equal(result,test)

  end

end
