require 'test_helper'

class PluginPolyAtTest < Minitest::Test

  def test_plugin_polyat

    outstats = File.join(File.expand_path(OUTPUT_PATH),"polyat_trimming_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"polyat_trimming_stats_cmd.txt")
    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')

    max_ram = '1G'
    cores = '1'
    sample_type = 'paired'
    save_unpaired = 'false'
    polyat_trimming_position = 'both'
    polyat_kmer_size = 31
    polyat_min_external_kmer_size = 9
    polyat_max_mismatches = 1
    polyat_additional_params = nil
    polyat_merging_pairs_trimming = 'true'

    options = {}

    options['max_ram'] = max_ram
    options['workers'] = cores
    options['sample_type'] = sample_type
    options['write_in_gzip'] = 'true'
    options['save_unpaired'] = save_unpaired
    options['polyat_trimming_position'] = polyat_trimming_position
    options['polyat_kmer_size'] = polyat_kmer_size
    options['polyat_min_external_kmer_size'] = polyat_min_external_kmer_size
    options['polyat_max_mismatches'] = polyat_max_mismatches

    options['polyat_additional_params'] = polyat_additional_params
    options['polyat_merging_pairs_trimming'] = polyat_merging_pairs_trimming

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    params = Params.new(faketemplate,options)

    plugin_list = 'PluginPolyAt'

# Single-ended sample

    options['sample_type'] = 'single-ended'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=9 hdist=1 rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['sample_type'] = 'paired'

    params = Params.new(faketemplate,options)

# Triming mode: Left

    options['polyat_trimming_position'] = 'left'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=9 hdist=1 lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA int=t in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Triming mode: Right

    options['polyat_trimming_position'] = 'right'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=9 hdist=1 rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA int=t in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])   

# Triming mode: Both

    options['polyat_trimming_position'] = 'both'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=9 hdist=1 rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA int=t in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Saving singles

    options['save_unpaired'] = 'true' 

    params = Params.new(faketemplate,options)

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_polyat_trimming.fastq.gz")

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=9 hdist=1 outs=#{outsingles} rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA int=t in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['save_unpaired'] = 'false'

    params = Params.new(faketemplate,options) 

# Adding some additional params

    options['polyat_aditional_params'] = "add_param=test"

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=9 hdist=1 rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA int=t add_param=test in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['polyat_additional_params'] = 'false'

  end

end