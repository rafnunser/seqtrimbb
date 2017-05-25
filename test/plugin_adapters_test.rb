require 'test_helper'

class PluginAdaptersTest < Minitest::Test

  def test_plugin_adapters

    adapters_db = File.join($DB_PATH,'adapters/adapters.fasta')
    outstats = File.join(File.expand_path(OUTPUT_PATH),"adapters_trimmings_stats.txt")

    options = {}

    options['max_ram'] = '1G'
    options['workers'] = '1'
    options['sample_type'] = 'paired'
    options['save_unpaired'] = 'false'
    options['adapters_db'] = adapters_db
    options['adapters_trimming_position'] = 'both'
    options['adapters_kmer_size'] = 15
    options['adapters_min_external_kmer_size'] = 8
    options['adapters_max_mismatches'] = 1

    options['adapters_additional_params'] = nil
    options['adapters_merging_pairs_trimming'] = 'true'

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    params = Params.new(faketemplate,options)

    plugin_list = 'PluginAdapters'

# Single-ended sample

    options['sample_type'] = 'single-ended'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['sample_type'] = 'paired'

    params = Params.new(faketemplate,options)

# Triming mode: Left

    options['adapters_trimming_position'] = 'left'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 lref=#{adapters_db} int=t tbo tpe in=stdin.fastq out=stdout.fastq stats=#{outstats}"
   
    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Triming mode: Right

    options['adapters_trimming_position'] = 'right'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} int=t tbo tpe in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])   

# Triming mode: Both

    options['adapters_trimming_position'] = 'both'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} int=t tbo tpe in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Saving singles

    options['save_unpaired'] = 'true' 

    params = Params.new(faketemplate,options)

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_adapters_trimming.fastq.gz")

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 outs=#{outsingles} rref=#{adapters_db} lref=#{adapters_db} int=t tbo tpe in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['save_unpaired'] = 'false' 

    params = Params.new(faketemplate,options)

# Trimming mode: paired without merging

    options['adapters_merging_pairs_trimming'] = 'false'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['adapters_merging_pairs_trimming'] = 'true'

    params = Params.new(faketemplate,options)

# Adding some additional params

    options['adapters_aditional_params'] = "add_param=test"

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} int=t tbo tpe add_param=test in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

  end

end
