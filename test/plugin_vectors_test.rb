require 'test_helper'

class PluginQualityTest < Minitest::Test

  def test_plugin_vectors

    db = 'vectors/vectors.fasta'

    temp_folder = File.join(RT_PATH,"temp")

    if Dir.exists?(temp_folder)

      FileUtils.remove_dir(temp_folder)

    end

    Dir.mkdir(temp_folder)

    FileUtils.cp_r $DB_PATH, temp_folder

    $DB_PATH = File.join(temp_folder,"DB")

    options={}

    options['max_ram'] = '1G'
    options['workers'] = '1'
    options['sample_type'] = 'paired'
    options['save_unpaired'] = 'false'

    vectors_db = File.join($DB_PATH,db)
    vectors_path = File.dirname(vectors_db)

    options['vectors_db'] = vectors_db
    options['vectors_trimming_position'] = 'both'
    options['vectors_kmer_size'] = 31
    options['vectors_min_external_kmer_size'] = 8
    options['vectors_max_mismatches'] = 1
    options['vectors_trimming_aditional_params'] = nil
    options['vectors_filtering_aditional_params'] = nil

    outstats1 = File.join(File.expand_path(OUTPUT_PATH),"vectors_trimming_stats.txt")
    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_vectors_trimming.fastq.gz")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"vectors_filtering_stats.txt")

    options['vectors_minratio'] = 0.56

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    CheckDatabase.new($DB_PATH,options['workers'],options['max_ram'])

    params = Params.new(faketemplate,options)

    plugin_list = 'PluginVectors'

# Single-ended file

    options['sample_type'] = 'single-ended'
   
    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 rref=#{vectors_db} lref=#{vectors_db} in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 | bbsplit.sh -Xmx1G t=1 minratio=0.56 ref=#{vectors_db} path=#{vectors_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['sample_type'] = 'paired'

    params = Params.new(faketemplate,options)

# Saving singles

    options['save_unpaired'] = 'true'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 outs=#{outsingles} rref=#{vectors_db} lref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 | bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{vectors_db} path=#{vectors_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['save_unpaired'] = 'false'

    params = Params.new(faketemplate,options)

# Vectors trimming position: left

    options['vectors_trimming_position'] = 'left'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 lref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 | bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{vectors_db} path=#{vectors_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Vectors trimming position: right

    options['vectors_trimming_position'] = 'right'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 rref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 | bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{vectors_db} path=#{vectors_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Vectors trimming position: both

    options['vectors_trimming_position'] = 'both'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 rref=#{vectors_db} lref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 | bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{vectors_db} path=#{vectors_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Adding aditional params

    options['vectors_trimming_aditional_params'] = 'add_param=test'

    options['vectors_filtering_aditional_params'] = 'add_param=test'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 k=31 mink=8 hdist=1 rref=#{vectors_db} lref=#{vectors_db} add_param=test int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 | bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{vectors_db} path=#{vectors_path} add_param=test in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    # Deleting $DB_PATH

    FileUtils.remove_dir(temp_folder)

    $DB_PATH = File.join(RT_PATH, "DB")

  end

end