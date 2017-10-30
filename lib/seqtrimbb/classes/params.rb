#########################################

# This class provided the methods to read the parameter's file (template) and to create the structure where will be storaged the param's name and the param's value
#########################################

class Params

  #Creates the structure and start the reading of parameter's file
  def initialize(options)

    @params = {}
    @comments = {}
    @plugin_comments = {}

    read_file(options[:template])
    save_options(options)

  end

  # Reads param's file
  def read_file(path_file)
  
     comments= []
     open_path_file = File.open(path_file)
     open_path_file.each_line do |line|
         line.chomp! # delete end of line
         if !line.empty?
             if !(line =~ /^\s*#/)   # if line is not a comment
               # extract the parameter's name in params[0] and the parameter's value in params[1]
                 line =~ /^\s*([^=]*)\s*=\s*(.*)\s*$/
                 params=[$1,$2]          
              # store in the hash the pair key/value, in our case will be name/value ,
              # that are save in params[0] and params[1],  respectively
                 if (!params[0].nil?) && (!params[1].nil?)
                     set_param(params[0].strip,params[1].strip,comments)
                     comments=[]
                 end
             else
                 comments << line.gsub(/^\s*#/,'')
             end 
        end 
     end 
     open_path_file.close
      if @params.empty?
        $LOG.warn "EMPTY PARAMETER FILE: #{path_file}. No parameters defined"
      end
    end

  end# end def

  # Save options
  def save_options(options)

    options.each do |opt_name,opt_value|
      # Save options
      set_param(opt_name.to_s,opt_value,"#{opt_name} value from input options")
    end

  end

  # Process saved params to add new useful general params
  def process_params(db_path)

     # Set db_path param (to access it from plugins)
     set_param('db_path',db_path,"# Databases path")

     # Writing options
     suffix = get_param('write_in_gzip') ? '.fastq.gz' : '.fastq'
     set_param('suffix',suffix,"# outfiles file extension")

     # test inputfiles format
     format_info = bbtools.execute('reformat',{in:nil,int:nil,out:nil,files:[get_param('file')[0]]})
     # paired count (to avoid false single-files)
     format_info[3] = 'paired' if get_param('file').count == 2
     # Set format info
     set_param('qual_format',format_info[0],"# Quality format value from input files")
     set_param('file_format',format_info[1],"# File format value from input files")
     set_param('sample_type',format_info[3],"# Sample type value from input files")
     # Preloading output params 
     # Setting outputfiles 
     case format_info[3]
         when 'paired'
          files_out = [File.join(File.expand_path(OUTPUT_PATH),"paired_1#{suffix}"),File.join(File.expand_path(OUTPUT_PATH),"paired_2#{suffix}")]
         when 'interleaved'
          files_out = [File.join(File.expand_path(OUTPUT_PATH),"interleaved#{suffix}")]
         when 'single-ended'
          files_out = [File.join(File.expand_path(OUTPUT_PATH),"sequences_#{suffix}")]
     end
     set_param('outputfiles',files_out,"# Preloaded output files")
 
     #Set and store default options. First add paired/interleaved information
     paired = (format_info[3] == 'paired' || format_info[3] == 'interleaved') ? 't' : 'f'
     default_options = { "in" => "stdin.fastq", "out" => "stdout.fastq", "int" => paired }
     set_param('default_options',files_out,"# Preloaded default BBtools input/output/paired_info")

     # Finally Overwrite template's params
     overwrite_params(get_param('overwrite_params').split(";")) if !get_param('overwrite_params').nil?

  end

  # Overwrite given params
  def overwrite_params(params)

    params.each do |param_to_overwrite|
        #Store param name and value
       param_to_overwrite =~ /^\s*([^=]*)\s*=\s*(.*)\s*$/
       params=[$1,$2]  
        #Set param
       set_param(params[0].to_s,params[1],"#{params[0]} value from input options")
       $LOG.debug "Overwriting param: #{params[0]}, with value: #{params[1]}"
    end

  end

  # Save param's file
  def save_file(path_file)

    f=File.open(path_file,'w')
    @plugin_comments.keys.sort.reverse.each do |plugin_name|
      f.puts "#"*50
      f.puts "# " + plugin_name
      f.puts "#"*50
      f.puts ''

      @plugin_comments[plugin_name].keys.each do |param|
        comment=get_comment(plugin_name,param)
        if !comment.nil? && !comment.empty? && comment!=''
          f.puts comment.map{|c| '# '+c if c!=''}
        end
        f.puts ''
        f.puts "#{param} = #{@params[param]}"
        f.puts ''
      end
    end
    f.close

  end# end def

  #  Prints the pair name/numeric-value for every parameter
  def print_parameters()
    @params.each do |clave, valor|
      #$LOG.debug  "The Parameter #{clave} have the value " +valor.to_s
      puts "#{clave} = #{valor} "
    end
  end

  # Return the parameter's list in an array
  def get_param(param)
    #$LOG.debug "Get Param:  #{@params[param]}"
    return @params[param]
  end

 
  def get_plugin
    plugin='General'
    # puts caller(2)[1]
    at = caller(2)[1]
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
      file = Regexp.last_match[1]
      line = Regexp.last_match[2].to_i
      method = Regexp.last_match[3]
      plugin=File.basename(file,File.extname(file))
    end  
  end
  
  def set_param(param,value,comment = nil)
     plugin=get_plugin
     # Store param in the hash params
     @params[param] = value
     # Store comment
     if get_comment(plugin,param).nil?
       set_comment(plugin,param,comment)
     end
  end
  
  def get_comment(plugin,param)
     res = nil
     if @plugin_comments[plugin]
       res =@plugin_comments[plugin][param]
     end
     return res
  end
  
  # Set comment
  def set_comment(plugin,param,comment)

     if !comment.is_a?(Array) && !comment.nil?
       comment=comment.split("\n").compact.map{|l| l.strip}
     end

     if @plugin_comments[plugin].nil?
       @plugin_comments[plugin]={}
     end

     old_comment=''
     # remove from other plugins
     @plugin_comments.each do |plugin_name,comments|
       if comments.keys.include?(param) && plugin_name!=plugin
         old_comment=comments[param]
         comments.delete(param)
       end
     end

     if comment.nil?
       comment=old_comment
     end

     # @comments[param]=(comment || [''])
     @plugin_comments[plugin][param]=(comment || [''])
     # puts @plugin_comments.keys.to_json

     # remove empty comments

     @plugin_comments.reverse_each do |plugin_name,comments|
       if comments.empty?
         @plugin_comments.delete(plugin_name)
       end
     end

  end
 
  # Returns true if exists the parameter and false if not
  def exist?(param_name)

     return @params.key?(param_name)

  end
 
  def check_plugin_list_param(errors,param_name)

     # get plugin list (raise if nil or empty)
     pl_list = get_param(param_name)
     raise ArgumentError.new('PluginList is nil or empty') if (pl_list.nil? || pl_list.empty?)
     # split and strips pl_list (String to Array of strings). 
     # the first plugin is always the reader, and last plugin is always the writer
     list = ['PluginReadInputBb'] + pl_list.strip.split(',').map!{|e| e.strip}.reject{|p| ['PluginReadInputBb','PluginSaveResultsBb'].include?(p)}
     list << 'PluginSaveResultsBb'
     # checks plugins_names
     current_plugins = Dir[File.join(File.join(SEQTRIM_PATH,'lib','seqtrimbb','plugins',"*.rb")].map!{|p| File.basename(p,'.rb')} + ['',' ',nil]
     list.each do |plugin_name|
         if !current_plugins.include?(plugin_name.decamelize)
             raise ArgumentError.new("Plugin #{plugin_name} does not exists")
         end
     end
     # Set updated pluginlist
     set_param(param_name,list.join(','))

  end

  def check_db_param(errors,db_param_name,cores,max_ram)
    
    # get databases list
    db_list=get_param(db_param_name)

    if [nil,'',' '].include?(db_list)
        errors.push "#{db_param_name} is empty. Specify a database or avoid this step."     
    end

    # for each database in the list check that database and is properly indexed. Also index external databases.
    db_list.split(/ |,/).each do |db|
    # External database
      if File.exist?(db)
    # Check and update
        db_update = CheckDatabaseExternal.new(db)
        db_update.update_index
        db_update.test_index(errors)
    # Internal database
      elsif Dir.exist?(File.join($DB_PATH,'fastas',db))
    # Test for errors
        db_update = CheckDatabase.new($DB_PATH)
        indexed_databases = db_update.info['indexed_databases']
        if !indexed_databases.include?(db)
            errors.push "#{db} database in #{db_param_name} is not updated"
        end
      else
        errors.push "#{db} database in #{db_param_name} doesn't exists"
      end    
    end   
    
  end
  
  def check_param(errors,param,param_class,default_value=nil, comment=nil)

     if !exists?(param)
       #if default_value.nil? #|| (default_value.is_a?(String) && default_value.empty?
          #nil_warnings = ['plugin_list']     
          #$LOG.info "#{param} value is nil" if nil_warnings.include?(param)
       #else
         set_param(param,default_value,comment)
       #end
     end

     s = get_param(param)
     set_comment(get_plugin,param,comment)

     begin
         case param_class
             when 'Integer'
                 r = Integer(s)
             when 'Float'
                 r = Float(s)
             when 'String'
                 r = String(s)
             when 'Array'
                 r = Array(s)
             when 'DB'
                 # it is a string
                 r = String(s)
                 # and must be a valid db
                 r = check_db_param(errors,param,cores,max_ram)
             when 'PluginList'
                 r = String(s)
                 r = check_plugin_list_param(errors,param)
         end
     rescue StandardError => e
         message="Current value is ##{s}#. "
         if param_class =='DB'
             message += e.message
         end
         errors.push "Param #{param} is not a valid #{param_class}. #{message}"
     end
     # end

  end

end
