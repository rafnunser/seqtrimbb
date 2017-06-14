require 'test_helper'

class PluginContaminantsTest < Minitest::Test

  def test_plugin_contaminants

    db = 'contaminants'

    temp_folder = File.join(RT_PATH,"temp")

    if Dir.exists?(temp_folder)

      FileUtils.remove_dir(temp_folder)

    end

    Dir.mkdir(temp_folder)

    FileUtils.cp_r $DB_PATH, temp_folder

    $DB_PATH = File.join(temp_folder,"DB")

    contaminants_db = File.join($DB_PATH,db)

    outstats = File.join(File.expand_path(OUTPUT_PATH),"#{db}_contaminants_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_contaminants_stats_cmd.txt")

    options = {}

    options['max_ram'] = '1G'
    options['workers'] = '1'
    options['sample_type'] = 'paired'
    options['save_unpaired'] = 'false'
    options['contaminants_dbs'] = db
    options['contaminants_minratio'] = 0.56
    options['contaminants_aditional_params'] = nil
    options['contaminants_decontamination_mode'] = 'regular'
    options['sample_species'] = 1

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    CheckDatabase.new($DB_PATH,options['workers'],options['max_ram'])

    path_refs = File.join(contaminants_db,'old_fastas_'+db+'.txt')

    db_list = {}

    File.open(path_refs).each_line do |line|

     line.chomp!
     ref = File.basename(line,".fasta")
     species0 = ref.split("_")
     species= species0[0..1].join(" ")

     db_list[species] = line

    end

    params = Params.new(faketemplate,options)

    plugin_list = 'PluginContaminants'

# Single-ended file

    options['sample_type'] = 'single-ended'

    params = Params.new(faketemplate,options)

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 ref=#{contaminants_db} path=#{contaminants_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['sample_type'] = 'paired'

    params = Params.new(faketemplate,options)

# Aditional params

    options['contaminants_aditional_params'] = 'add_param=test'

    params = Params.new(faketemplate,options)

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{contaminants_db} add_param=test in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['contaminants_aditional_params'] = nil

    params = Params.new(faketemplate,options)

# External single file database
    
    db = 'Contaminant_one.fasta'

    contaminants_db = File.join($DB_PATH,'contaminants',db)

    path_to_db_file = File.dirname(contaminants_db)

    options['contaminants_dbs'] = contaminants_db

    params = Params.new(faketemplate,options)

    db_name = File.basename(db,".fasta")

    outstats = File.join(File.expand_path(OUTPUT_PATH),"#{db_name}_contaminants_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"#{db_name}_contaminants_stats_cmd.txt")

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{path_to_db_file} in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# External database
    
    db = 'contaminants'

    contaminants_db = File.join($DB_PATH,db)

    options['contaminants_dbs'] = contaminants_db

    params = Params.new(faketemplate,options)

    db_name = db.split("/").last

    outstats = File.join(File.expand_path(OUTPUT_PATH),"#{db_name}_contaminants_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"#{db_name}_contaminants_stats_cmd.txt")

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{contaminants_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['contaminants_dbs'] = 'contaminants'

# Exclude mode : species

    db = 'contaminants'

    outstats = File.join(File.expand_path(OUTPUT_PATH),"#{db}_contaminants_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPLUGINSTATS),"#{db}_contaminants_stats_cmd.txt")

    options['contaminants_dbs'] = db

    options['contaminants_decontamination_mode'] = 'exclude species'

    options['sample_species'] = 'Contaminant one'

    params = Params.new(faketemplate,options)

    db_ref = Array.new

    db_list.each do |contaminant,path|

      db_ref.push(path) if contaminant != options['sample_species']

    end

    db_ref = db_ref.join(",")

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{db_ref} path=#{OUTPUT_PATH} in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Exclude mode :  genus

    options['contaminants_decontamination_mode'] = 'exclude genus'

    options['sample_species'] = 'Contaminant two'

    params = Params.new(faketemplate,options)

    paths_to_contaminants = File.join($DB_PATH,'contaminants/Another_contaminant.fasta')

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{paths_to_contaminants} path=#{OUTPUT_PATH} in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Two databases
    
    contaminants_db1 = File.join($DB_PATH,'contaminants')

    contaminants_db2 = File.join($DB_PATH,'vectors')

    options['contaminants_dbs'] = 'contaminants,vectors'

    options['contaminants_decontamination_mode'] = 'regular'

    outstats1 = File.join(File.expand_path(OUTPUT_PATH),"contaminants_contaminants_stats.txt")
    outstats3 = File.join(File.expand_path(OUTPLUGINSTATS),"contaminants_contaminants_stats_cmd.txt")

    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"vectors_contaminants_stats.txt")
    outstats4 = File.join(File.expand_path(OUTPLUGINSTATS),"vectors_contaminants_stats_cmd.txt")

    params = Params.new(faketemplate,options)

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db1} path=#{contaminants_db1} in=stdin.fastq out=stdout.fastq refstats=#{outstats1} 2> #{outstats3} | bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db2} path=#{contaminants_db2} in=stdin.fastq out=stdout.fastq refstats=#{outstats2} 2> #{outstats4}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])    

    # Deleting $DB_PATH

    FileUtils.remove_dir(temp_folder)

    $DB_PATH = File.join(RT_PATH, "DB")

  end
  
end
