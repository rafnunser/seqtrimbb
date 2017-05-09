require 'test_helper'

class SeqtrimbbTest < Minitest::Test

  def test_that_it_has_a_version_number
    refute_nil ::Seqtrimbb::VERSION
  end

  def test_it_does_something_useful
    assert false
  end

  def test_plugins

  	require 'plugin_manager.rb'
  	require 'params.rb'
    @params = {}
    $DB_PATH = File.expand_path(File.join(ROOT_PATH, "DB"))
    OUTPUT_PATH = "/test/testoutput"

    test_plugins_adapters
    test_plugins_contaminants
    test_plugins_user_filter
    test_plugins_quality
    test_plugins_lowcomplexity
    test_plugin_vectors
    test_plugins_mate_pairs
    test_plugins_input
    test_plugins_save   

  end

  def test_plugin_adapters

    require 'plugin_adapters.rb'

    @params['max_ram'] = '1G'
    @params['cores'] = '1'
    @params['sample_type'] = 'paired'
    @params['save_singles'] = 'false'

    adapters_db = File.join($DB_PATH,'adapters/adapters.fasta')
    outstats = File.join(File.expand_path(OUTPUT_PATH),"adapters_trimmings_stats.txt")

    @params['adapters_db'] = adapters_db
    @params['adapters_trimming_position'] = 'both'
    @params['adapters_kmer_size'] = 15
    @params['adapters_min_external_kmer_size'] = 8
    @params['adapters_max_mismatches'] = 1

    @params['adapters_additional_params'] = 'false'
    @params['adapters_mergin_pairs_trimming'] = 'true'

# Single-ended sample

    @params['sample_type'] = 'single'

    plugin_list = 'PluginAdapters'

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Triming mode: Left

    @params['adapters_trimming_position'] = 'left'

    plugin_list = 'PluginAdapters'

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 lref=#{adapters_db} int=t tpe tbo in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Triming mode: Right

    @params['adapters_trimming_position'] = 'right'

    plugin_list = 'PluginAdapters'

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} int=t tpe tbo in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)   

# Triming mode: Both

    @params['adapters_trimming_position'] = 'both'

    plugin_list = 'PluginAdapters'

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} int=t tpe tbo in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Saving singles

    @params['save_singles'] = 'true' 

    plugin_list = 'PluginAdapters'

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_adapters_trimming.fastq.gz")

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 outs=#{outsingles} rref=#{adapters_db} lref=#{adapters_db} int=t tpe tbo in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Trimming mode: paired without merging

    @params['adapters_mergin_pairs_trimming'] = 'false'

    plugin_list = 'PluginAdapters'

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Adding some additional params

    @params['adapters_additional_params'] = "add_param=test"

    plugin_list = 'PluginAdapters'

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} int=t tpe tbo add_param=test in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)


  end

  def test_plugin_contaminants

    params

    plugin_list = 'PluginContaminants'


  end

  def test_plugin_user_filter

    params

    plugin_list = 'PluginUserFilter'


  end

  def test_plugin_quality

    require 'plugin_quality.rb'

    @params['max_ram'] = '1G'
    @params['cores'] = '1'
    @params['sample_type'] = 'paired'
    @params['save_singles'] = 'false'

    threshold = 20

    @params['quality_threshold'] = threshold
    @params['quality_trimming_position'] = 'both'
    @params['quality_aditional_params'] = 'false'

    plugin_list = 'PluginQuality'


# Trimming single-ended sample

    @params['sample_type'] = 'single'

    plugin_list = 'PluginQuality'

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=rl in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

  end

# Trimming mode: left

    @params['quality_trimming_position'] = 'left'

    plugin_list = 'PluginQuality'

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=l int=t in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

 # Trimming mode: right

    @params['quality_trimming_position'] = 'right'

    plugin_list = 'PluginQuality'

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=r int=t in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

 # Trimming mode: both

    @params['quality_trimming_position'] = 'both'

    plugin_list = 'PluginQuality'

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=rl int=t in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

 # Aditional params

    @params['quality_aditional_params'] = 'add_param=test'

    plugin_list = 'PluginQuality'

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=rl int=t add_param=test in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)


  end

  def test_plugin_lowcomplexity

    params

    plugin_list = 'PluginLowComplexity'


  end

  def test_plugin_mate_pairs

    params

    plugin_list = 'PluginMatePairs'


  end

  def test_plugin_vectors

    params

    plugin_list = 'PluginVectors'


  end

  def test_plugin_input

    params

    plugin_list = 'PluginReadInputBb'


  end

  def test_plugin_save

    params

    plugin_list = 'PluginSaveResultsBb'


  end


end
