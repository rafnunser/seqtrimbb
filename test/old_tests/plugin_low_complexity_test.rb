require 'test_helper'

class PluginLowComplexityTest < Minitest::Test

  def test_plugin_lowcomplexity

    options = {}

    outstats = File.join(File.expand_path(OUTPUT_PATH),"low_complexity_stats.txt")
    nativelibdir = File.join($BBPATH,'jni')
    classp = File.join($BBPATH,'current')

    max_ram = '1G'
    cores = '1'
    sample_type = 'paired'
    save_unpaired = 'false'
    
    options['max_ram'] = max_ram
    options['workers'] = cores
    options['sample_type'] = sample_type
    options['write_in_gzip'] = 'true'
    options['save_unpaired'] = save_unpaired
    options['complexity_threshold'] = 0.01
    options['minlength'] = 50
    options['low_complexity_aditional_params'] = nil
    plugin_list = 'PluginLowComplexity'

    faketemplate = File.join($DB_PATH,"faketemplate.txt")

    params = Params.new(faketemplate,options)

# Filtering single-ended sample

    options['sample_type'] = 'single-ended'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} entropy=0.01 entropywindow=50 in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['sample_type'] = 'paired'

    params = Params.new(faketemplate,options)

# Minlength < 50

    options['minlength'] = 49

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} entropy=0.01 entropywindow=49 int=t in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['minlength'] = 50

    params = Params.new(faketemplate,options)

 # Saving singles

    options['save_unpaired'] = 'true'

    params = Params.new(faketemplate,options)

    outsingles = File.join(File.expand_path(OUTPUT_PATH),"singles_low_complexity_filtering.fastq.gz")

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} entropy=0.01 entropywindow=50 outs=#{outsingles} int=t in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

    options['save_unpaired'] = 'false'

    params = Params.new(faketemplate,options)

 # Adding additional params

    options['low_complexity_aditional_params'] = 'add_param=test'

    params = Params.new(faketemplate,options)

    result = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{max_ram} -Xms#{max_ram} -cp #{classp} jgi.BBDuk2 t=#{cores} entropy=0.01 entropywindow=50 int=t add_param=test in=stdin.fastq out=stdout.fastq 2> #{outstats}"

    manager = PluginManager.new(plugin_list,params)

    test = manager.execute_plugins()

    assert_equal(result,test[0])

  end
end