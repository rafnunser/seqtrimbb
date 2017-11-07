require 'test_helper'

class PluginVectorsTest < Minitest::Test

  def test_plugin_vectors

    db = 'vectors'

    temp_folder = File.join(RT_PATH,"temp")

    if Dir.exists?(temp_folder)
      FileUtils.remove_dir(temp_folder)
    end

    Dir.mkdir(temp_folder)
    FileUtils.cp_r $DB_PATH, temp_folder
    $DB_PATH = File.join(temp_folder,"DB")

    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')
    max_ram = '1g'
    cores = '1'
    sample_type = 'paired'
    save_unpaired = 'false'
    minratio = 0.80

    options={}

    options['max_ram'] = max_ram
    options['workers'] = cores
    options['write_in_gzip'] = 'true'
    options['sample_type'] = sample_type
    options['save_unpaired'] = save_unpaired

    options['vectors_db'] = db
    options['vectors_trimming_position'] = 'both'
    options['vectors_kmer_size'] = 31
    options['vectors_min_external_kmer_size'] = 11
    options['vectors_max_mismatches'] = 1
    options['vectors_trimming_aditional_params'] = nil
    options['vectors_filtering_aditional_params'] = nil

    outstats1 = File.join(File.expand_path(OUTPLUGINSTATS),"vectors_trimming_stats.txt")
    outstats3 = File.join(File.expand_path(OUTPLUGINSTATS),"vectors_trimming_stats_cmd.txt")
    outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"vectors_filtering_stats.txt")
    outstats4 = File.join(File.expand_path(OUTPLUGINSTATS),"vectors_filtering_stats_cmd.txt")

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_vectors_trimming.fastq.gz")

    options['vectors_minratio'] = minratio

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    CheckDatabase.new($DB_PATH,options['workers'],options['max_ram'])

    params = Params.new(faketemplate,options)

    vectors_db = File.join($DB_PATH,'fastas',db,db+'.fasta')
    vectors_path = File.join($DB_PATH,'indices',db)

    plugin_list = 'PluginVectors'

# Single-ended file

    options['sample_type'] = 'single-ended'
   
    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=11 hdist=1 rref=#{vectors_db} lref=#{vectors_db} in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 2> #{outstats3} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} path=#{vectors_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats2} 2> #{outstats4}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['sample_type'] = 'paired'

    params = Params.new(faketemplate,options)

# Saving singles

    options['save_unpaired'] = 'true'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=11 hdist=1 outs=#{outsingles} rref=#{vectors_db} lref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 2> #{outstats3} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{vectors_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats2} 2> #{outstats4}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['save_unpaired'] = 'false'

    params = Params.new(faketemplate,options)

# Vectors trimming position: left

    options['vectors_trimming_position'] = 'left'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=11 hdist=1 lref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 2> #{outstats3} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{vectors_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats2} 2> #{outstats4}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Vectors trimming position: right

    options['vectors_trimming_position'] = 'right'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=11 hdist=1 rref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 2> #{outstats3} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{vectors_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats2} 2> #{outstats4}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Vectors trimming position: both

    options['vectors_trimming_position'] = 'both'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=11 hdist=1 rref=#{vectors_db} lref=#{vectors_db} int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 2> #{outstats3} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{vectors_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats2} 2> #{outstats4}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Adding aditional params

    options['vectors_trimming_aditional_params'] = 'add_param=test'
    options['vectors_filtering_aditional_params'] = 'add_param=test'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} k=31 mink=11 hdist=1 rref=#{vectors_db} lref=#{vectors_db} add_param=test int=t in=stdin.fastq out=stdout.fastq stats=#{outstats1} restrictleft=58 restrictright=58 2> #{outstats3} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{vectors_path} add_param=test in=stdin.fastq out=stdout.fastq refstats=#{outstats2} 2> #{outstats4}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    # Deleting $DB_PATH

    FileUtils.remove_dir(temp_folder)

    $DB_PATH = File.join(RT_PATH, "DB")

  end

end