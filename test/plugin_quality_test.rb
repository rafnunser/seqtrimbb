require 'test_helper'

class PluginQualityTest < Minitest::Test

  def test_plugin_quality

    outstats = File.join(OUTPUT_PATH,"quality_trimming_stats.txt")

    options = {}

    options['max_ram'] = '1G'
    options['workers'] = '1'
    options['sample_type'] = 'paired'
    options['save_unpaired'] = 'false'

    threshold = 20

    options['quality_threshold'] = threshold
    options['quality_trimming_position'] = 'both'
    options['quality_aditional_params'] = nil

    plugin_list = 'PluginQuality'

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    params = Params.new(faketemplate,options)

# Trimming single-ended sample

    options['sample_type'] = 'single-ended'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=rl in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['sample_type'] = 'paired'

    params = Params.new(faketemplate,options)

# Trimming mode: left

    options['quality_trimming_position'] = 'left'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=l int=t in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

 # Trimming mode: right

    options['quality_trimming_position'] = 'right'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=r int=t in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

 # Trimming mode: both

    options['quality_trimming_position'] = 'both'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=rl int=t in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

 # Aditional params

    options['quality_aditional_params'] = 'add_param=test'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 trimq=#{threshold} qtrim=rl int=t add_param=test in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

  end

end