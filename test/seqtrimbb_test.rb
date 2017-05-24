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

    plugin_list = 'PluginAdapters'

# Single-ended sample

    @params['sample_type'] = 'single-ended'

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['sample_type'] = 'paired'

# Triming mode: Left

    @params['adapters_trimming_position'] = 'left'

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 lref=#{adapters_db} int=t tpe tbo in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Triming mode: Right

    @params['adapters_trimming_position'] = 'right'

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} int=t tpe tbo in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)   

# Triming mode: Both

    @params['adapters_trimming_position'] = 'both'

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} int=t tpe tbo in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Saving singles

    @params['save_singles'] = 'true' 

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_adapters_trimming.fastq.gz")

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 outs=#{outsingles} rref=#{adapters_db} lref=#{adapters_db} int=t tpe tbo in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['save_singles'] = 'false' 

# Trimming mode: paired without merging

    @params['adapters_mergin_pairs_trimming'] = 'false'

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['adapters_mergin_pairs_trimming'] = 'true'

# Adding some additional params

    @params['adapters_additional_params'] = "add_param=test"

    result = "bbduk2.sh -Xmx1G t=1 k=15 mink=8 hdist=1 rref=#{adapters_db} lref=#{adapters_db} int=t tpe tbo add_param=test in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['adapters_additional_params'] = 'false'

  end

  def test_plugin_polyat

    @params['max_ram'] = '1G'
    @params['cores'] = '1'
    @params['sample_type'] = 'paired'
    @params['save_singles'] = 'false'

    outstats = File.join(File.expand_path(OUTPUT_PATH),"polyat_trimmings_stats.txt")

    @params['polyat_trimming_position'] = 'both'
    @params['polyat_kmer_size'] = 31
    @params['polyat_min_external_kmer_size'] = 9
    @params['polyat_max_mismatches'] = 1

    @params['polyat_additional_params'] = 'false'

    plugin_list = 'PluginPolyAT'

# Single-ended sample

    @params['sample_type'] = 'single-ended'

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=9 hdist=1 rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA int=t in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['sample_type'] = 'paired'

# Triming mode: Left

    @params['polyat_trimming_position'] = 'left'

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=9 hdist=1 lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA int=t in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Triming mode: Right

    @params['polyat_trimming_position'] = 'right'

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=9 hdist=1 rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA int=t in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)   

# Triming mode: Both

    @params['polyat_trimming_position'] = 'both'

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=9 hdist=1 rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA int=t in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Saving singles

    @params['save_singles'] = 'true' 

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_polyat_trimming.fastq.gz")

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=9 hdist=1 outs=#{outsingles} rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA int=t in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['save_singles'] = 'false' 

# Adding some additional params

    @params['polyat_additional_params'] = "add_param=test"

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=9 hdist=1 rliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA lliteral=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA int=t add_param=test in=stdin.fastq out=stdout.fastq stats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['polyat_additional_params'] = 'false'

  end

  def test_plugin_contaminants

   require 'plugin_contaminants.rb'

    @params['max_ram'] = '1G'
    @params['cores'] = '1'
    @params['sample_type'] = 'paired'

    outstats = File.join(File.expand_path(OUTPUT_PATH),"contaminants_contaminants_stats.txt")
    contaminants_db = File.join($DB_PATH,'contaminants')

    @params['contaminants_dbs'] = 'contaminants'
    @params['contaminants_minratio'] = 0.56
    @params['contaminants_decontamination_mode'] = 'normal'
    @params['contaminants_additional_params'] = 'false'
    @params['sample_species'] = 1

    plugin_list = 'PluginContaminants'

# Single-ended file

    @params['sample_type'] = 'single-ended'

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 ref=#{contaminants_db} path=#{contaminants_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['sample_type'] = 'paired'

# Aditional params

    @params['contaminants_additional_params'] = 'add_param=test'

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{contaminants_db} add_param=test in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['contaminants_additional_params'] = 'false'

# External single file database

    contaminants_db = File.join($DB_PATH,'contaminants','Contaminant_one.fasta')

    path_to_db_file = File.dirname(contaminants_db)

    @params['contaminants_dbs'] = contaminants_db

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{path_to_db_file} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# External database

    contaminants_db = File.join($DB_PATH,'contaminants')

    @params['contaminants_dbs'] = contaminants_db

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{contaminants_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['contaminants_dbs'] = 'contaminants'

# Exclude mode : species

    @params['contaminants_decontamination_mode'] = 'exclude species'

    @params['sample_species'] = 'Contaminant one'

    paths_to_contaminants = [File.join($DB_PATH,'contaminants/Another_contaminant.fasta'),File.join($DB_PATH,'contaminants/Contaminant_two.fasta')]

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{paths_to_contaminants} path=#{contaminants_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Exclude mode :  genus

    @params['contaminants_decontamination_mode'] = 'exclude genus'

    @params['sample_species'] = 'Contaminant two'

    paths_to_contaminants = File.join($DB_PATH,'contaminants/Another_contaminant.fasta'

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{paths_to_contaminants} path=#{contaminants_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Two databases
    
    contaminants_db1 = File.join($DB_PATH,'contaminants')

    contaminants_db2 = File.join($DB_PATH,'vectors')

    @params['contaminants_dbs'] = 'contaminants,vectors'

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db1} path=#{contaminants_db1} in=stdin.fastq out=stdout.fastq refstats=#{outstats} | bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db2} path=#{contaminants_db2} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)    

  end

  def test_plugin_user_filter

    @params['max_ram'] = '1G'
    @params['cores'] = '1'
    @params['sample_type'] = 'paired'

    outstats = File.join(File.expand_path(OUTPUT_PATH),"contaminants_user_filter_stats.txt")
    user_filter_db = File.join($DB_PATH,'contaminants')

    @params['user_filter_dbs'] = 'contaminants'
    @params['user_filter_minratio'] = 0.56
    @params['user_filter_additional_params'] = 'false'
    @params['user_filter_species'] = 'Contaminant one,Contaminant two'

    plugin_list = 'PluginUserFilter'

 # Two species

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{contaminants_db} out_Contaminant_one=Contaminant_one_out.fastq.gz out_Contaminant_two=Contaminant_two_out.fastq.gz in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

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

    @params['sample_type'] = 'single-ended'

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=rl in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['sample_type'] = 'paired'

# Trimming mode: left

    @params['quality_trimming_position'] = 'left'

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=l int=t in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

 # Trimming mode: right

    @params['quality_trimming_position'] = 'right'

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=r int=t in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

 # Trimming mode: both

    @params['quality_trimming_position'] = 'both'

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=rl int=t in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

 # Aditional params

    @params['quality_aditional_params'] = 'add_param=test'

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

    @params['sample_type'] = 'single-ended'

    result = "bbduk2.sh -Xmx1G t=1 entropy=0.01 entropywindow=50 in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['sample_type'] = 'paired'

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

    @params['save_singles'] = 'false'

 # Adding additional params

    @params['low_complexity_aditional_params'] = 'add_param=test'

    result = "bbduk2.sh -Xmx1G t=1 entropy=0.01 entropywindow=50 int=t add_param=test in=stdin.fastq out=stdout.fastq"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

  end

  def test_plugin_mate_pairs

    @params['max_ram'] = '1G'
    @params['cores'] = '1'
    @params['sample_type'] = 'paired'
    @params['linker_literal_seq'] = 'AGCTTCGAAGCTTCGA' 

    adapters_db = File.join($DB_PATH,'adapters/adapters.fasta')
    outstats_adapters = File.join(File.expand_path(OUTPUT_PATH),"LMP_adapters_trimmings_stats.txt")
    outstats_linkers = File.join(File.expand_path(OUTPUT_PATH),"LMP_linker_trimmings_stats.txt")

    @params['adapters_db'] = adapters_db
    @params['adapters_kmer_size'] = 15
    @params['adapters_min_external_kmer_size'] = 8
    @params['adapters_max_mismatches'] = 1

    outlongmate = File.join(File.expand_path(OUTPUT_PATH),"longmate.fastq.gz")
    outunknown = File.join(File.expand_path(OUTPUT_PATH),"unknown.fastq.gz")

    require 'PluginMatePairs'

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

   result.push("bbduk2.sh -Xmx1G t=1 rref=#{adapters_db} lref=#{adapters_db} k=15 mink=8 hdist=1 stats=#{outstats_adapters} #{input_frag} out=stdout.fastq tpe tbo | bbduk2.sh -Xmx1G t=1 in=stdin.fastq out=stdout.fastq kmask=J k=19 hdist=1 mink=11 hdist2=0 literal=#{linkers} stats=#{outstats_linkers} | splitnextera.sh -Xmx1G t=1 int=t in=stdin.fastq out=#{outlongmate} outu=#{outunknown}")
   result.push("cat #{outlongmate} #{outunknown} | bbduk2.sh -Xmx1G t=1 int=t in=stdin.fastq.gz #{output_frag} lliteral=#{unkmask} rliteral=#{unkmask} k=19 hdist=1 mink=11 hdist2=0 minlength=50")
   
   test = PluginMatePairs.test_cmd(@params)

   assert_equal(result,test)

# Interleaved sample

   file1 = "testfile_1.fastq"

   $SAMPLEFILES = []

   $SAMPLEFILES[0] = file1

   input_frag = "in=#{file1}"

   unkmask = '"JJJJJJJJJJJJ"'

   output_frag = "out=untreated_LMPreads.fastq.gz"

   result = Array.new

   result.push("bbduk2.sh -Xmx1G t=1 rref=#{adapters_db} lref=#{adapters_db} k=15 mink=8 hdist=1 stats=#{outstats_adapters} #{input_frag} out=stdout.fastq tpe tbo | bbduk2.sh -Xmx1G t=1 in=stdin.fastq out=stdout.fastq kmask=J k=19 hdist=1 mink=11 hdist2=0 literal=#{linkers} stats=#{outstats_linkers} | splitnextera.sh -Xmx1G t=1 int=t in=stdin.fastq out=#{outlongmate} outu=#{outunknown}")
   result.push("cat #{outlongmate} #{outunknown} | bbduk2.sh -Xmx1G t=1 int=t in=stdin.fastq.gz #{output_frag} lliteral=#{unkmask} rliteral=#{unkmask} k=19 hdist=1 mink=11 hdist2=0 minlength=50")
   
   test = PluginMatePairs.test_cmd(@params)

   assert_equal(result,test)

  end

  def test_plugin_vectors

    @params['max_ram'] = '1G'
    @params['cores'] = '1'
    @params['sample_type'] = 'paired'
    @params['save_singles'] = 'false'

    vectors_db = File.join($DB,"vectors/vectors.fasta")

    @params['vectors_db'] = vectors_db
    @params['vectors_trimming_position'] = 'both'
    @params['vectors_kmer_size'] = 31
    @params['vectors_min_external_kmer_size'] = 8
    @params['vectors_max_mismatches'] = 1
    @params['vectors_additional_params'] = 'false'

    outstats1 = File.join(File.expand_path(OUTPUT_PATH),"vectors_trimming_stats.txt")
    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_vectors_trimming.fastq.gz")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"filtering_vectors_stats.txt")

    @params['vectors_minratio0'] = 0.56

    plugin_list = 'PluginVectors'

# Single-ended file

    @params['sample_type'] = 'single-ended'

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 rref=#{vectors_db} lref=#{vectors_db} in=stdin.fastq out=stdout.fastq stats=#{outstats1} | bbsplit -Xmx1G t=1 minratio=0.56 ref=#{vectors_db} path=#{vectors_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['sample_type'] = 'paired'

# Saving singles

    @params['save_singles'] = 'true'

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 outs=#{outsingles} rref=#{vectors_db} lref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} | bbsplit -Xmx1G t=1 minratio=0.56 int=t ref=#{vectors_db} path=#{vectors_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

    @params['save_singles'] = 'false'

# Vectors trimming position: left

    @params['vectors_trimming_position'] = 'left'

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 lref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} | bbsplit -Xmx1G t=1 minratio=0.56 int=t ref=#{vectors_db} path=#{vectors_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Vectors trimming position: right

    @params['vectors_trimming_position'] = 'right'

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 rref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} | bbsplit -Xmx1G t=1 minratio=0.56 int=t ref=#{vectors_db} path=#{vectors_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Vectors trimming position: both

    @params['vectors_trimming_position'] = 'both'

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 rref=#{vectors_db} lref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} | bbsplit -Xmx1G t=1 minratio=0.56 int=t ref=#{vectors_db} path=#{vectors_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

# Adding aditional params

    @params['vectors_additional_params'] = 'add_param=test'

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 rref=#{vectors_db} lref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} | bbsplit -Xmx1G t=1 minratio=0.56 int=t ref=#{vectors_db} path=#{vectors_db} add_param=test in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugings()

    assert_equal(result,test)

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
