require 'test_helper'

class PluginAdaptersTest < Minitest::Test

  def test_plugin_adapters
    
    adapters_db = File.join($DB_PATH,'fastas/adapters/adapters.fasta')
    outstats = File.join(File.expand_path(OUTPUT_PATH),"adapters_trimming_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"adapters_trimming_stats_cmd.txt")
    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')

    max_ram = '1G'
    cores = '1'
    sample_type = 'paired'
    save_unpaired = 'false'
    adapters_db = File.join($DB_PATH,'fastas/adapters/adapters.fasta')
    adapters_trimming_position = 'both'
    adapters_kmer_size = 15
    adapters_min_external_kmer_size = 8
    adapters_max_mismatches = 1

    adapters_aditional_params = nil
    adapters_merging_pairs_trimming = 'true'

    options = {}

    options['max_ram'] = max_ram
    options['workers'] = cores
    options['sample_type'] = sample_type
    options['write_in_gzip'] = 'true'
    options['save_unpaired'] = save_unpaired
    options['adapters_db'] = 'adapters'
    options['adapters_trimming_position'] = adapters_trimming_position
    options['adapters_kmer_size'] = adapters_kmer_size
    options['adapters_min_external_kmer_size'] = adapters_min_external_kmer_size
    options['adapters_max_mismatches'] = adapters_max_mismatches

    options['adapters_aditional_params'] = adapters_aditional_params
    options['adapters_merging_pairs_trimming'] = adapters_merging_pairs_trimming

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    params = Params.new(faketemplate,options)

    plugin_list = 'PluginAdapters'

# Single-ended sample

    options['sample_type'] = 'single-ended'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches} rref=#{adapters_db} lref=#{adapters_db} in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)
    
    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['sample_type'] = 'paired'

    params = Params.new(faketemplate,options)

# Triming mode: Left

    options['adapters_trimming_position'] = 'left'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches} lref=#{adapters_db} int=t tbo tpe in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"
   
    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Triming mode: Right

    options['adapters_trimming_position'] = 'right'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches} rref=#{adapters_db} int=t tbo tpe in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])   

# Triming mode: Both

    options['adapters_trimming_position'] = 'both'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches} rref=#{adapters_db} lref=#{adapters_db} int=t tbo tpe in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Saving singles

    options['save_unpaired'] = 'true' 

    params = Params.new(faketemplate,options)

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_adapters_trimming.fastq.gz")

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches} outs=#{outsingles} rref=#{adapters_db} lref=#{adapters_db} int=t tbo tpe in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['save_unpaired'] = 'false' 

    params = Params.new(faketemplate,options)

# Trimming mode: paired without merging

    options['adapters_merging_pairs_trimming'] = 'false'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches} rref=#{adapters_db} lref=#{adapters_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['adapters_merging_pairs_trimming'] = 'true'

    params = Params.new(faketemplate,options)

# Adding some additional params

    options['adapters_aditional_params'] = "add_param=test"

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches} rref=#{adapters_db} lref=#{adapters_db} int=t tbo tpe add_param=test in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Multiple-file database

    adapters_db = Dir[File.join($DB_PATH,'fastas/contaminants/','*.fasta*')].join(",")
    options['adapters_db'] = 'contaminants'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=#{adapters_kmer_size} mink=#{adapters_min_external_kmer_size} hdist=#{adapters_max_mismatches} rref=#{adapters_db} lref=#{adapters_db} int=t tbo tpe add_param=test in=stdin.fastq out=stdout.fastq stats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

  end

end
