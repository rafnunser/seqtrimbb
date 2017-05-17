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

   require 'plugin_contaminants.rb'

    @params['max_ram'] = '1G'
    @params['cores'] = '1'
    @params['sample_type'] = 'paired'

    outstats = File.join(File.expand_path(OUTPUT_PATH),"contaminants_contaminants_stats.txt")

    @params['contaminants_dbs'] = contaminants_db
    @params['contaminants_minratio'] = 0.56
    @params['contaminants_decontamination_mode'] = 'normal'
    @params['contaminants_additional_params'] = 'false'
    @params['sample_species'] = 1

    plugin_list = 'PluginContaminants'

# Single-ended file

    contaminants_db = File.join($DB_PATH,'contaminants')

    @params['sample_type'] = 'single'
    
    plugin_list = 'PluginContaminants'

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 ref=#{contaminants_db} path=#{contaminants_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Aditional params

    @params['contaminants_additional_params'] = 'add_param=test'

    contaminants_db = File.join($DB_PATH,'contaminants')

    @params['sample_type'] = 'single'
    
    plugin_list = 'PluginContaminants'

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{contaminants_db} add_param=test in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)


# External single file database

    contaminants_db = File.join($DB_PATH,'contaminants','Candida_albicans.fasta')
    path_to_db_file = File.dirname(contaminants_db)

    @params['contaminants_dbs'] = contaminants_db
    
    plugin_list = 'PluginContaminants'

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{path_to_db_file} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# External database

    contaminants_db = File.join($DB_PATH,'contaminants')

    @params['contaminants_dbs'] = contaminants_db
    
    plugin_list = 'PluginContaminants'

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{contaminants_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Exclude mode : species

    @params['contaminants_decontamination_mode'] = 'exclude species'

    @params['sample_species'] = 'Candida albicans'

    path_to_contaminants = 
    
    plugin_list = 'PluginContaminants'

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{contaminants_db} add_param=test in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)


# Exclude mode :  genus

    @params['contaminants_decontamination_mode'] = 'exclude genus'

    @params['sample_species'] = 'Candida albicans'

    path_to_contaminants = 
    
    plugin_list = 'PluginContaminants'

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{contaminants_db} add_param=test in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Two databases
    
    contaminants_db1 = File.join($DB_PATH,'contaminants')

    contaminants_db2 = File.join($DB_PATH,'vectors')

    @params['contaminants_dbs'] = 'contaminants,vectors'
    
    plugin_list = 'PluginContaminants'

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db1} path=#{contaminants_db1} in=stdin.fastq out=stdout.fastq refstats=#{outstats} | bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db2} path=#{contaminants_db2} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)    

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

    require 'plugin_low_complexity.rb'

    @params['max_ram'] = '1G'
    @params['cores'] = '1'
    @params['sample_type'] = 'paired'
    @params['save_singles'] = 'false'

    @params['complexity_threshold'] = 0.01
    @params['minlength'] = 50
    @params['low_complexity_aditional_params'] = 'false'

    plugin_list = 'PluginLowComplexity'


# Filtering single-ended sample

    @params['sample_type'] = 'single'

    result = "bbduk2.sh -Xmx1G t=1 entropy=0.01 entropywindow=50 in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

  end

# Minlength < 50

    @params['minlength'] = 49

    result = "bbduk2.sh -Xmx1G t=1 entropy=0.01 entropywindow=49 int=t in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

 # Saving singles

    @params['save_singles'] = 'true'

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_low_complexity_trimming.fastq.gz")

    result = "bbduk2.sh -Xmx1G t=1 entropy=0.01 entropywindow=50 int=t outs=#{outsingles} in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

 # Adding additional params

    @params['low_complexity_aditional_params'] = 'add_param=test'

    result = "bbduk2.sh -Xmx1G t=1 entropy=0.01 entropywindow=50 int=t add_param=test in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

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

    require 'plugin_read_input_bb.rb'

    @params['max_ram'] = '1G'
    @params['cores'] = '1'
    @params['sample_type'] = 'paired'
    @params['file_format'] = 'fastq'

    plugin_list = 'PluginReadInputBb'


 # Single-ended sample

   @params['sample_type'] = 'single-ended'

   file = "testfile.fastq"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file

   result = "reformat.sh -Xmx1G t=1 in=#{file} out=stdout.fastq"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugings()

   assert_equal(result,test)

 # Interleaved sample

   @params['sample_type'] = 'interleaved'

   file = "testfile.fastq"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file

   result = "reformat.sh -Xmx1G t=1 in=#{file} int=t out=stdout.fastq"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugings()

   assert_equal(result,test)

 # Paired sample

   @params['sample_type'] = 'paired'

   file1 = "testfile_1.fastq"
   file2 = "testfile_2.fastq"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file1
   $SAMPLEFILES[1] = file2

   result = "reformat.sh -Xmx1G t=1 in=#{file1} in2=#{file2} out=stdout.fastq"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugings()

   assert_equal(result,test)

 # Fasta sample with qual

   @params['sample_type'] = 'paired'
   @params['file_format'] = 'fasta'

   file1 = "testfile_1.fasta"
   file2 = "testfile_2.fasta"
   qual1 = "testqual_1.qual"
   qual2 = "testqual_2.qual"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file1
   $SAMPLEFILES[1] = file2

   $SAMPLEQUALS = []

   $SAMPLEQUALS[0] = qual1
   $SAMPLEQUALS[1] = qual2

   result = "reformat.sh -Xmx1G t=1 in=#{file1} in2=#{file2} qual=#{qual1} qual1=#{qual2} out=stdout.fastq"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugings()

   assert_equal(result,test)


 # Fasta sample without qual

   @params['sample_type'] = 'paired'
   @params['file_format'] = 'fasta'

   file1 = "testfile_1.fasta"
   file2 = "testfile_2.fasta"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file1
   $SAMPLEFILES[1] = file2

   result = "reformat.sh -Xmx1G t=1 in=#{file1} in2=#{file2} q=40 out=stdout.fastq"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugings()

   assert_equal(result,test)

  end

  def test_plugin_save

    require 'plugin_save_results_bb.rb'

    @params['max_ram'] = '1G'
    @params['cores'] = '1'
    @params['sample_type'] = 'paired'
    @params['minlength'] = 50

    plugin_list = 'PluginSaveResultsBb'

 # Single-ended sample

   @params['sample_type'] = 'single-ended'

   file = "testoutfile.fastq"

   $OUTPUTFILES = []

   $OUTPUTFILES[0] = file

   result = "reformat.sh -Xmx1G t=1 in=stdin.fastq out=#{file}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugings()

   assert_equal(result,test)

 # Interleaved sample

   @params['sample_type'] = 'interleaved'

   file = "testoutfile.fastq"

   $OUTPUTFILES = []

   $OUTPUTFILES[0] = file

   result = "reformat.sh -Xmx1G t=1 int=t in=stdin.fastq out=#{file}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugings()

   assert_equal(result,test)

 # Paired sample

   @params['sample_type'] = 'paired'

   file1 = "testoutfile_1.fastq"
   file2 = "testoutfile_2.fastq"

   $OUTPUTFILES = []

   $OUTPUTFILES[0] = file1
   $OUTPUTFILES[1] = file2

   result = "reformat.sh -Xmx1G t=1 int=t in=stdin.fastq out=#{file1} out2=#{file2}"

   manager = PluginManager.new(plugin_list,params)

   test = manager.execute_plugings()

   assert_equal(result,test)

  end


end
