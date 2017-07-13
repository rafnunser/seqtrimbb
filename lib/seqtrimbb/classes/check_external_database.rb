class CheckDatabaseExternal

 attr_reader :info

 def initialize(dir,workers,ram)

  @db_path = dir
  @cores = Integer(workers)
  @max_ram = ram

  @info = Hash.new

  get_info

 end

 def get_info

  #Getting and setting database info

  if File.directory?(@db_path)
    db_name=@db_path.split("/").last
    if File.writable?(@db_path)
     db_index=File.join(@db_path,'index')
    else
     db_index=File.join(OUTPUT_PATH,'temp_indices',db_name)
    end
    old_status_file = File.join(db_index,'fastas_'+db_name+'.txt')
    update_error = File.join(db_index,'update_stderror_'+db_name+'.txt') 

    @info["db_index"] = db_index
    @info["db_name"] = db_name
    @info["db_fastas"] = old_status_file
    @info["db_stderror"] = update_error
  else
    db_name=File.basename(@db_path).split(".")[0]
    if File.writable?(File.dirname(@db_path))
     db_index=File.join(File.dirname(@db_path),'index')
    else
     db_index=File.join(OUTPUT_PATH,'temp_indices',db_name)
    end
    update_error = File.join(db_index,'update_stderror_'+db_name+'.txt')
    @info["db_index"] = db_index
    @info["db_name"] = db_name
    @info["db_fastas"] = @db_path
    @info["db_stderror"] = update_error
  end

 end

 def update_index

  nativelibdir = File.join($BBPATH,'jni')
  classp = File.join($BBPATH,'current')

  $LOG.info("Checking external database index at #{@db_path} for updates")

  if File.directory?(@db_path)

    db_index = @info["db_index"]
    db_name = @info["db_name"]
    old_status_file = @info["db_fastas"]
    update_error = @info["db_stderror"]

    # Loading fastas from database (current files) and from status file (previous update)

    dir_fastas = File.join(@db_path,"*.fasta*")
       
    current_fastas = Dir[dir_fastas].sort

    old_fastas = File.readlines(old_status_file).map(&:chomp) if File.exists?(old_status_file)

    if !Dir.exists?(File.join(db_index,'ref')) or !File.exists?(old_status_file) or !current_fastas == old_fastas

        # Removing old index and old status file

        FileUtils.rm_rf(db_index) if Dir.exists?(db_index)
        Dir.mkdir(db_index)

        FileUtils.rm(update_error) if File.exists?(update_error)

        FileUtils.rm(old_status_file) if File.exists?(old_status_file)

        # cmd execution

        $LOG.info("Updating #{db_name} database index at: #{db_index}")

        cmd = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{@max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{@cores} ref=#{@db_path} path=#{db_index} 2> #{update_error}"

        system(cmd)

        # writing new status file

        IO.write(old_status_file, current_fastas.join("\n"))

    end

  else

    db_index = @info["db_index"]
    db_name = @info["db_name"]
    update_error = @info["db_stderror"]

    if !Dir.exists?(File.join(db_index,'ref'))
       
        # Removing old index and old status file

        FileUtils.rm_rf(db_index) if Dir.exists?(db_index)

        Dir.mkdir(db_index)

        # cmd execution

        $LOG.info("Updating #{db_name} database index at: #{db_index}")

        cmd = "java -Djava.library.path=#{nativelibdir} -ea -Xmx#{@max_ram} -cp #{classp} align2.BBSplitter ow=t fastareadlen=500 t=#{@cores} ref=#{@db_path} path=#{db_index} 2> #{update_error}"

        system(cmd)

    end
  end

  $LOG.info("External database #{@db_path} index is updated")

 end

 def test_index(errors)

  # Test for errors in indexing

  $LOG.info("Checking for errors in external databases index update")
               
  if Dir.exists?(@info["db_index"]) and File.exists?(@info["db_stderror"])

    File.open(@info["db_stderror"]).each do |line|

      line.chomp!

      if !line.empty?

        if (line =~ /Error/) || (line =~ /Exception in thread/)
          errors.push "Internal error in #{@info["db_name"]} index update. For more details: #{@update_error}. To retry, remove #{@info["db_index"]} folder"
        end
      end
    end         
  else
    errors.push "Internal error in #{@info["db_name"]} index update. For more details: #{@update_error}. To retry, remove #{@info["db_index"]} folder"
  end
 end
 
end
