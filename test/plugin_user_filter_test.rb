require 'test_helper'

class PluginUserFilterTest < Minitest::Test

  def test_plugin_user_filter

    db = 'contaminants'
    temp_folder = File.join(RT_PATH,"temp")

    if Dir.exists?(temp_folder)
      FileUtils.remove_dir(temp_folder)
    end

    Dir.mkdir(temp_folder)
    Dir.mkdir(File.join(temp_folder,'temp_indices'))

    FileUtils.cp_r $DB_PATH, temp_folder

    $DB_PATH = File.join(temp_folder,"DB")

    db_index = File.join($DB_PATH,'indices',db)

    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')
    max_ram = '1g'
    cores = '1'
    sample_type = 'paired'
    minlength = 50
    minratio = 0.56
    options = {}

    options['max_ram'] = max_ram
    options['workers'] = cores
    options['sample_type'] = sample_type
    options['write_in_gzip'] = true

    preoutstats = File.join(File.expand_path(OUTPUT_PATH),"user_filter_stats_minlength_discard.txt")

    outstats = File.join(File.expand_path(OUTPUT_PATH),"contaminants_user_filter_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"contaminants_user_filter_stats_cmd.txt")
    output = File.join(File.expand_path(OUTPUT_PATH),"filtered_files")

    user_filter_db = File.join($DB_PATH,db)

    options['user_filter_db'] = db
    options['user_filter_minratio'] = minratio
    options['user_filter_aditional_params'] = nil
    options['user_filter_species'] = nil
    options['minlength'] = 50

    plugin_list = 'PluginUserFilter'

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    CheckDatabase.new($DB_PATH,options['workers'],options['max_ram'])

    path_refs = File.join($DB_PATH,'status_info','fastas_'+db+'.txt')

    db_list = []

    File.open(path_refs).each_line do |line|
       line.chomp!
       species = File.basename(line).split(".")[0].split("_")[0..1].join(" ")
       db_list.push(species)
    end 

    params = Params.new(faketemplate,options)

    precmd = "java -ea -Xmx#{max_ram} -cp #{classp} jgi.ReformatReads t=#{cores} in=stdin.fastq minlength=#{minlength} int=t out=stdout.fastq 2> #{preoutstats}"

 # Without species

    result = "#{precmd} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{db_index} basename=#{output}/%_out_#.fastq.gz in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

 # Two species

    options['sample_type'] = 'interleaved'
    options['user_filter_species'] = 'Contaminant one,Contaminant two'

    params = Params.new(faketemplate,options)

    result = "#{precmd} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{db_index} out_Contaminant_one=#{output}/Contaminant_one_out.fastq.gz out_Contaminant_two=#{output}/Contaminant_two_out.fastq.gz in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

 # Single file database

    db = File.join($DB_PATH,'fastas/contaminants','Contaminant_one.fasta')
    outstats = File.join(File.expand_path(OUTPUT_PATH),"Contaminant_one_user_filter_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"Contaminant_one_user_filter_stats_cmd.txt")

    #Extract info
    db_update = CheckDatabaseExternal.new(db,cores,max_ram)
    db_info = db_update.info
    # Single-file database
    db_refs = db
    db_index = db_info["db_index"]
    db_name = db_info["db_name"]

    options['user_filter_db'] = db
    options['user_filter_species'] = nil

    params = Params.new(faketemplate,options)

    result = "#{precmd} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{db_index} basename=#{output}/%_out.fastq.gz in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)
    test = manager.execute_plugins()

    assert_equal(result,test[0])

 # External database

    db = File.join($DB_PATH,'fastas','contaminants')
    outstats = File.join(File.expand_path(OUTPUT_PATH),"contaminants_user_filter_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"contaminants_user_filter_stats_cmd.txt")
    
    #Extract info
    db_update = CheckDatabaseExternal.new(db,cores,max_ram)
    db_info = db_update.info
    #External directory database
    db_index = db_info["db_index"]
    db_name = db_info["db_name"]

    options['user_filter_db'] = db

    params = Params.new(faketemplate,options)

    result = "#{precmd} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{db_index} basename=#{output}/%_out.fastq.gz in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)
    test = manager.execute_plugins()

    assert_equal(result,test[0])

 # Deleting temp folder

    FileUtils.remove_dir(temp_folder)

    $DB_PATH = File.join(RT_PATH, "DB")

  end

end