require 'test_helper'

class PluginLowComplexityTest < Minitest::Test

  def test_plugin_lowcomplexity

    options = {}

    outstats = File.join(File.expand_path(OUTPUT_PATH),"low_complexity_stats.txt")

    options['max_ram'] = '1G'
    options['workers'] = '1'
    options['sample_type'] = 'paired'
    options['save_unpaired'] = 'false'

    options['complexity_threshold'] = 0.01
    options['minlength'] = 50
    options['low_complexity_aditional_params'] = nil
    plugin_list = 'PluginLowComplexity'

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    params = Params.new(faketemplate,options)

# Filtering single-ended sample

    options['sample_type'] = 'single-ended'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 entropy=0.01 entropywindow=50 in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['sample_type'] = 'paired'

    params = Params.new(faketemplate,options)

# Minlength < 50

    options['minlength'] = 49

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 entropy=0.01 entropywindow=49 int=t in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['minlength'] = 50

    params = Params.new(faketemplate,options)

 # Saving singles

    options['save_unpaired'] = 'true'

    params = Params.new(faketemplate,options)

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_low_complexity_filtering.fastq.gz")

    result = "bbduk2.sh -Xmx1G t=1 entropy=0.01 entropywindow=50 outs=#{outsingles} int=t in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['save_unpaired'] = 'false'

    params = Params.new(faketemplate,options)

 # Adding additional params

    options['low_complexity_aditional_params'] = 'add_param=test'

    params = Params.new(faketemplate,options)

    result = "bbduk2.sh -Xmx1G t=1 entropy=0.01 entropywindow=50 int=t add_param=test in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

  end
end