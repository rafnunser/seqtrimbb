#########################################

# This class provided the methods to read the parameter's file and to create the structure where will be storaged the param's name and the param's numeric-value
#########################################
#require 'scbi_fasta'

class Params


  #Creates the structure and start the reading of parameter's file
  def initialize(path, options)

    @params = {}
    @comments = {}
    # @param_order={}
    @mids = {}
    @ab_adapters={}
    @adapters={}
    @linkers = {}
    @clusters = {}

    @plugin_comments = {}

    read_file(path)

    #save options
    options.each do |opt_name,opt_value|
      set_param(opt_name.to_s,opt_value,"#{opt_name} value from input options")
    end
    #puts @params.to_json
  end

  # Reads param's file
  def read_file(path_file)

    if path_file && File.exists?(path_file)
      comments= []
      File.open(path_file).each_line do |line|
        line.chomp! # delete end of line

        if !line.empty?
          if !(line =~ /^\s*#/)   # if line is not a comment
            # extract the parameter's name in params[0] and the parameter's value in params[1]
            #params = line.split(/\s*=\s*/)

            # store in the hash the pair key/value, in our case will be name/numeric-value ,
            # that are save in params[0] and params[1],  respectively
            #if (!params[0].nil?) && (!params[1].nil?)
            #  set_param(params[0].strip,params[1].strip,comments)
            #  comments=[]
            #end

            line =~ /^\s*([^=]*)\s*=\s*(.*)\s*$/
            params=[$1,$2]
              
            # store in the hash the pair key/value, in our case will be name/numeric-value ,
            # that are save in params[0] and params[1],  respectively
            if (!params[0].nil?) && (!params[1].nil?)
              set_param(params[0].strip,params[1].strip,comments)
              comments=[]
            end


            $LOG.debug "read: #{params[0]}=#{params[1]}" if !$LOG.nil?
            
          else
            comments << line.gsub(/^\s*#/,'')
          end # end if comentario
        end #end if line
      end #end each
      if @params.empty?
        puts "INVALID PARAMETER FILE: #{path_file}. No parameters defined"
        exit
      end

    end
  end# end def

  # Reads param's file
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

     @params[param] = value

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
 
  # Returns true if exists the parameter and nil if don't
  def exists?(param_name)
     return !@params[param_name].nil?
   end
 
  def check_plugin_list_param(errors,param_name)
     # get plugin list
     pl_list=get_param(param_name)

     # puts pl_list,param_name
     list=pl_list.split(',')

     list.map!{|e| e.strip}

     # always the first plugin is the reader, and last plugin is the writer
     list.delete('PluginSaveResultsBb')
     list.delete('PluginReadInputBb')
     list=['PluginReadInputBb']+list
     list << 'PluginSaveResultsBb'

     set_param(param_name,list.join(','))

   end

  # def split_databases(db_param_name)
  def check_db_param(errors,db_param_name)
  
    # check that database exists and is formatted   
    
  end
  
  
  def self.generate_sample_params

     filename = 'sample_params.txt'
     x=1
     while File.exists?(filename)
       filename = "sample_params#{x}.txt"
       x+=1
     end

     f=File.open(filename,'w')
     f.puts "SAMPLE_PARAMS"
     f.close

     puts "Sample params file generated: #{filename}"

   end
  
  def check_param(errors,param,param_class,default_value=nil, comment=nil)

     if !exists?(param)
       if default_value.nil? #|| (default_value.is_a?(String) && default_value.empty?)
         errors.push "The param #{param} is required and no default value is available"
       else
         set_param(param,default_value,comment)
       end
     end

     s = get_param(param)


     set_comment(get_plugin,param,comment)

     # check_class=Object.const_get(param_class)
     begin

       case param_class
       when 'Integer'
         r = Integer(s)
       when 'Float'
         r = Float(s)
       when 'String'
         r = String(s)
       when 'DB'
         # it is a string
         r = String(s)
         # and must be a valid db

         r = check_db_param(errors,param)

       when 'PluginList'
         r=String(s)
         r= check_plugin_list_param(errors,param)
       end

     rescue Exception => e
       message="Current value is ##{s}#. "
       if param_class=='DB'
         message += e.message
       end

       errors.push "Param #{param} is not a valid #{param_class}. #{message}"
     end
     # end

   end

end
