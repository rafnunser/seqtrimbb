require 'test_helper'

class PluginContaminantsTest < Minitest::Test

  def test_plugin_contaminants

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

    outstats = File.join(File.expand_path(OUTPUT_PATH),"#{db}_contaminants_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_contaminants_stats_cmd.txt")

    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')
    max_ram = '1g'
    cores = '1'
    sample_type = 'paired'
    save_unpaired = 'false'
    minratio = 0.56

    options = {}

    options['max_ram'] = max_ram
    options['workers'] = cores
    options['sample_type'] = sample_type
    options['save_unpaired'] = save_unpaired
    options['contaminants_db'] = db
    options['contaminants_minratio'] = minratio
    options['contaminants_aditional_params'] = nil
    options['contaminants_decontamination_mode'] = 'regular'
    options['sample_species'] = 1

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    CheckDatabase.new($DB_PATH,options['workers'],options['max_ram'])

    path_refs = File.join($DB_PATH,'status_info','fastas_'+db+'.txt')

    db_list = {}

    File.open(path_refs).each_line do |line|
       line.chomp!
       species = File.basename(line).split(".")[0].split("_")[0..1].join(" ")
       db_list[species] = line
    end 

    params = Params.new(faketemplate,options)

    plugin_list = 'PluginContaminants'

# Single-ended file

    options['sample_type'] = 'single-ended'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} path=#{db_index} in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['sample_type'] = 'paired'

    params = Params.new(faketemplate,options)

# Aditional params

    options['contaminants_aditional_params'] = 'add_param=test'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{db_index} add_param=test in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['contaminants_aditional_params'] = nil

    params = Params.new(faketemplate,options)

# External single file database
    
    db = File.join($DB_PATH,'fastas/contaminants','Contaminant_one.fasta')

    #Extract info
    db_update = CheckDatabaseExternal.new(db,cores,max_ram)
    db_info = db_update.info
    # Single-file database
    db_refs = db
    db_index = db_info["db_index"]
    db_name = db_info["db_name"]

    options['contaminants_db'] = db

    params = Params.new(faketemplate,options)

    outstats = File.join(File.expand_path(OUTPUT_PATH),"#{db_name}_contaminants_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"#{db_name}_contaminants_stats_cmd.txt")

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{db_index} in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# External database
    
    db = File.join($DB_PATH,'fastas','contaminants')

    #Extract info
    db_update = CheckDatabaseExternal.new(db,cores,max_ram)
    db_info = db_update.info
    #External directory database
    db_index = db_info["db_index"]
    db_name = db_info["db_name"]

    options['contaminants_db'] = db

    params = Params.new(faketemplate,options)

    outstats = File.join(File.expand_path(OUTPUT_PATH),"#{db_name}_contaminants_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"#{db_name}_contaminants_stats_cmd.txt")

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{db_index} in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['contaminants_dbs'] = 'contaminants'

# Exclude mode : species

    db = 'contaminants'

    options['contaminants_db'] = db

    outstats = File.join(File.expand_path(OUTPUT_PATH),"#{db}_contaminants_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_contaminants_stats_cmd.txt")
    index_path = File.join(OUTPUT_PATH,'temp_indices',db_name)

    options['contaminants_decontamination_mode'] = 'exclude species'

    options['sample_species'] = 'Contaminant one'

    params = Params.new(faketemplate,options)

    db_ref = Array.new

    db_list.each do |contaminant,path|

      db_ref.push(path) if contaminant != options['sample_species']

    end

    db_ref = db_ref.join(",")

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t ref=#{db_ref} path=#{index_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Exclude mode :  genus

    options['contaminants_decontamination_mode'] = 'exclude genus'

    options['sample_species'] = 'Contaminant two'

    params = Params.new(faketemplate,options)

    paths_to_contaminants = File.join($DB_PATH,'fastas/contaminants/Another_contaminant.fasta')

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t ref=#{paths_to_contaminants} path=#{index_path} in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Two databases
    
    contaminants_db1 = File.join($DB_PATH,'indices/contaminants')

    contaminants_db2 = File.join($DB_PATH,'indices/vectors')

    options['contaminants_db'] = 'contaminants,vectors'

    options['contaminants_decontamination_mode'] = 'regular'

    outstats1 = File.join(File.expand_path(OUTPUT_PATH),"contaminants_contaminants_stats.txt")
    outstats3 = File.join(File.expand_path(OUTPLUGINSTATS),"contaminants_contaminants_stats_cmd.txt")

    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"vectors_contaminants_stats.txt")
    outstats4 = File.join(File.expand_path(OUTPLUGINSTATS),"vectors_contaminants_stats_cmd.txt")

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{contaminants_db1} in=stdin.fastq out=stdout.fastq refstats=#{outstats1} 2> #{outstats3} | java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{cores} minhits=1 maxindel=20 qtrim=rl untrim=t trimq=6 minratio=#{minratio} int=t path=#{contaminants_db2} in=stdin.fastq out=stdout.fastq refstats=#{outstats2} 2> #{outstats4}"

    manager = PluginManager.new(plugin_list,params)
    manager.check_plugins_params(params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])    

# Deleting $DB_PATH

  FileUtils.remove_dir(temp_folder)

  $DB_PATH = File.join(RT_PATH, "DB")

  end
  
end
