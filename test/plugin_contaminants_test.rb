require 'test_helper'

class PluginContaminantsTest < Minitest::Test

  def test_plugin_contaminants

    db = 'contaminants'
    contaminants_db = File.join($DB_PATH,db)
    outstats = File.join(File.expand_path(OUTPUT_PATH),"#{db}_contaminants_stats.txt")

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

    params = Params.new(faketemplate,options)

    plugin_list = 'PluginContaminants'

# Single-ended file

    options['sample_type'] = 'single-ended'

    params = Params.new(faketemplate,options)

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 ref=#{contaminants_db} path=#{contaminants_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['sample_type'] = 'paired'

    params = Params.new(faketemplate,options)

# Aditional params

    options['contaminants_aditional_params'] = 'add_param=test'

    params = Params.new(faketemplate,options)

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{contaminants_db} add_param=test in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

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

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{path_to_db_file} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

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

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db} path=#{contaminants_db} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['contaminants_dbs'] = 'contaminants'

# Exclude mode : species

    db = 'contaminants'

    outstats = File.join(File.expand_path(OUTPUT_PATH),"#{db}_contaminants_stats.txt")

    options['contaminants_dbs'] = db

    options['contaminants_decontamination_mode'] = 'exclude species'

    options['sample_species'] = 'Contaminant one'

    params = Params.new(faketemplate,options)

    paths_to_contaminant1 = File.join($DB_PATH,'contaminants/Another_contaminant.fasta')
    paths_to_contaminant2 = File.join($DB_PATH,'contaminants/Contaminant_two.fasta')

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{paths_to_contaminant2},#{paths_to_contaminant1} path=#{OUTPUT_PATH} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Exclude mode :  genus

    options['contaminants_decontamination_mode'] = 'exclude genus'

    options['sample_species'] = 'Contaminant two'

    params = Params.new(faketemplate,options)

    paths_to_contaminants = File.join($DB_PATH,'contaminants/Another_contaminant.fasta')

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{paths_to_contaminants} path=#{OUTPUT_PATH} in=stdin.fastq out=stdout.fastq refstats=#{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

# Two databases
    
    contaminants_db1 = File.join($DB_PATH,'contaminants')

    contaminants_db2 = File.join($DB_PATH,'vectors')

    options['contaminants_dbs'] = 'contaminants,vectors'

    options['contaminants_decontamination_mode'] = 'regular'

    outstats1 = File.join(File.expand_path(OUTPUT_PATH),"contaminants_contaminants_stats.txt")

    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"vectors_contaminants_stats.txt")

    params = Params.new(faketemplate,options)

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db1} path=#{contaminants_db1} in=stdin.fastq out=stdout.fastq refstats=#{outstats1} | bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{contaminants_db2} path=#{contaminants_db2} in=stdin.fastq out=stdout.fastq refstats=#{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])    

  end
  
end
