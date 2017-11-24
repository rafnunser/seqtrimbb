######################################
# Test databases support
######################################
require 'test_helper'

class DatabasesTest < Minitest::Test

         def test_database

              # PATHs options hashes
                 setup_databases
                 db_path = File.join(OUTPUT_PATH,'DB')
                 databases = ['adapters','contaminants','contaminants_seqtrim1','cont_bacteria','cont_fungi','cont_mitochondrias','cont_plastids','cont_ribosome','cont_viruses','vectors']
                 json = File.join(db_path,'status_info','databases_status_info.json')
                 bb_path = BBPATH
                 bbtools = BBtools.new(bb_path)
              ## Initialize databases object
                 stbb_db = DatabasesSupportHandler.new({:workers => 1},db_path,bbtools)
              # Init internal support
                 stbb_db.init_internal({:databases_action => 'replace', :databases_list => Array.new})
              # Test info (databases, directory, and modified)
                 assert_equal(stbb_db.info['databases'],databases)
                 assert_equal(stbb_db.info['dir'],db_path)
                 assert_equal(stbb_db.info['modified'],true)
              # Maintenance (test check)
                 stbb_db.maintenance_internal({:check_db => true})
              # Test structure
                 ['indices','status_info'].map { |d| assert_equal(Dir.exist?(File.join(db_path,d)),true) }
              # Test update
                 databases.map { |d| assert_equal(Dir.exist?(File.join(db_path,'indices',d,'ref')),true) }
              # Test info
                 assert_equal(stbb_db.info['indexed_databases'],databases)
                 assert_equal(stbb_db.info['installed_databases'],databases)
                 assert_equal(stbb_db.info['obsolete_databases'],Array.new)
                 random_database = databases.sample
                 random_info = {}
                 random_info['path'] = File.join(db_path,'fastas',random_database)
                 random_info['index'] = File.join(db_path,'indices',random_database)
                 random_info['update_error_file'] = File.join(db_path,'status_info','update_stderror_'+random_database+'.txt') 
                 random_info['name'] = random_database
                 random_info['fastas'] = Dir[File.join(random_info['path'],"*.fasta*")].sort
                 random_info['list'] = random_info['fastas'].map { |fasta| File.basename(fasta).sub(/\Wfasta(\Wgz)?/,'').sub(/_/,' ') }
                 random_info['size'] = random_info['fastas'].map { |file| File.size?(file) }.inject(:+)
                 random_info['index_size'] = Dir[File.join(random_info['index'],'ref',"*/*/*")].map { |file| File.size?(file) }.inject(:+)
                 assert_equal(stbb_db.info[random_database],random_info)
              # Test Save
                 stbb_db.save_json(stbb_db.info,json)
                 old_info = stbb_db.info
                 old_info.delete('modified')

              # Reinit internal support and test changes
                 stbb_db = DatabasesSupportHandler.new({:workers => 1},db_path,bbtools)
                 stbb_db.init_internal({:databases_action => 'replace', :databases_list => Array.new})
                 stbb_db.maintenance_internal({:check_db => true})
                 assert_equal(stbb_db.info,old_info)
                 stbb_db = DatabasesSupportHandler.new({:workers => 1},db_path,bbtools)
                 arr_sample = databases.sample(4)
                 stbb_db.init_internal({:databases_action => 'replace', :databases_list => arr_sample})
                 assert_equal(stbb_db.info['databases'].sort,arr_sample.sort)
                 stbb_db.init_internal({:databases_action => 'add', :databases_list => databases - arr_sample})
                 assert_equal(stbb_db.info['databases'].sort,databases.sort)
                 stbb_db.init_internal({:databases_action => 'remove', :databases_list => databases - arr_sample})
                 assert_equal(stbb_db.info['databases'].sort,arr_sample.sort)
                 stbb_db.init_internal({:databases_action => 'replace', :databases_list => ['default']})
                 assert_equal(stbb_db.info['databases'].sort,databases.sort)

              # Init external support
              ## build two external databases(One folder, one file)
                 sample_file =random_info['fastas'].sample
                 ext_dbs = [File.join(db_path,'external_database'),File.join(db_path,File.basename(sample_file))]
                 FileUtils.cp sample_file,db_path
                 Dir.mkdir(ext_dbs[0])
                 FileUtils.cp Dir[File.join(db_path,'fastas',databases.sample,"*.fasta*")],ext_dbs[0]

              # Set the external databases
                 stbb_db.set_external(ext_dbs)
                 assert_equal(stbb_db.external_db_info['databases'],ext_dbs)
              # Maintenance external
				         stbb_db.maintenance_external(ext_dbs)
				         assert_equal(stbb_db.external_db_info['indexed_databases'],ext_dbs)
				         assert_equal(stbb_db.external_db_info['obsolete_databases'],Array.new)
				         folder_database = ext_dbs[0]
				         folder_info = {}
				         folder_info['name'] = File.basename(ext_dbs[0]).gsub(/\Wfasta(\Wgz)?/,'')
				         folder_info['path'] = folder_database
				         folder_info['index'] = File.join(folder_database,'index')
				         folder_info['update_error_file'] = File.join(folder_info['index'],'update_stderror_'+folder_info['name']+'.txt') 
				         folder_info['fastas'] = Dir[File.join(folder_info['path'],"*.fasta*")].sort
 				         folder_info['list'] = folder_info['fastas'].map { |fasta| File.basename(fasta).sub(/\Wfasta(\Wgz)?/,'').sub(/_/,' ') }
				         folder_info['size'] = folder_info['fastas'].map { |file| File.size?(file) }.inject(:+)
				         folder_info['index_size'] = Dir[File.join(folder_info['index'],'ref',"*/*/*")].map { |file| File.size?(file) }.inject(:+)
				         assert_equal(stbb_db.external_db_info[folder_database],folder_info)
				         file_database = ext_dbs[1]
 				         file_info = {}
				         file_info['name'] = File.basename(ext_dbs[1]).gsub(/\Wfasta(\Wgz)?/,'')
				         file_info['path'] = file_database
				         file_info['index'] = File.join(File.dirname(file_database),'index')
				         file_info['update_error_file'] = File.join(file_info['index'],'update_stderror_'+file_info['name']+'.txt') 
				         file_info['fastas'] = [file_database]
				         file_info['list'] = file_info['fastas'].map { |fasta| File.basename(fasta).sub(/\Wfasta(\Wgz)?/,'').sub(/_/,' ') }
				         file_info['size'] = file_info['fastas'].map { |file| File.size?(file) }.inject(:+)
				         file_info['index_size'] = Dir[File.join(file_info['index'],'ref',"*/*/*")].map { |file| File.size?(file) }.inject(:+)
				         assert_equal(stbb_db.external_db_info[file_database],file_info)
				         stbb_db.maintenance_external(ext_dbs)

              #CLEAN UP
                 clean_up

         end

end
