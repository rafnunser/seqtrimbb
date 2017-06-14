require 'test_helper'

class PluginUserFilterTest < Minitest::Test

  def test_plugin_user_filter

    db = 'contaminants'

    temp_folder = File.join(RT_PATH,"temp")

    if Dir.exists?(temp_folder)

      FileUtils.remove_dir(temp_folder)

    end

    Dir.mkdir(temp_folder)

    FileUtils.cp_r $DB_PATH, temp_folder

    $DB_PATH = File.join(temp_folder,"DB")

    options = {}

    options['max_ram'] = '1G'
    options['workers'] = '1'
    options['sample_type'] = 'paired'

    outstats = File.join(File.expand_path(OUTPUT_PATH),"contaminants_user_filter_stats.txt")
    outstats2 = File.join(File.expand_path(OUTPUT_PATH),"contaminants_user_filter_stats_cmd.txt")

    user_filter_db = File.join($DB_PATH,db)

    options['user_filter_dbs'] = db
    options['user_filter_minratio'] = 0.56
    options['user_filter_aditional_params'] = nil
    options['user_filter_species'] = 'Contaminant one,Contaminant two'

    plugin_list = 'PluginUserFilter'

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    CheckDatabase.new($DB_PATH,options['workers'],options['max_ram'])

    params = Params.new(faketemplate,options)

 # Two species

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{user_filter_db} path=#{user_filter_db} out_Contaminant_one=Contaminant_one_out.fastq.gz out_Contaminant_two=Contaminant_two_out.fastq.gz in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

 # Without species

    options['user_filter_species'] = nil

    params = Params.new(faketemplate,options)

    result = "bbsplit.sh -Xmx1G t=1 minratio=0.56 int=t ref=#{user_filter_db} path=#{user_filter_db} basename=%_out.fastq.gz in=stdin.fastq out=stdout.fastq refstats=#{outstats} 2> #{outstats2}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

 # Deleting temp folder

    FileUtils.remove_dir(temp_folder)

    $DB_PATH = File.join(RT_PATH, "DB")

  end

end