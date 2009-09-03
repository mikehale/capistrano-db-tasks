module Database
  class Base 
    attr_accessor :config
    def initialize(cap_instance)
      @cap = cap_instance
    end
    
    def mysql?
      @config['adapter'] == 'mysql'
    end
    
    def credentials
      " -u #{@config['username']} " + (@config['password'] ? " -p\"#{@config['password']}\" " : '')
    end
    
    def database
      @config['database']
    end
    
  private
    def dump_cmd(file)
      "mysqldump --add-drop-table #{credentials} #{database} | bzip2 -c > #{file}"
    end

    def import_cmd(file)
      "bunzip2 -c #{file} | mysql #{credentials} -D #{database}"
    end
  end

  class Remote < Base
    attr_accessor :output_file
    def initialize(cap_instance)
      super(cap_instance)
      @cap.run("cat #{@cap.current_path}/config/database.yml") { |c, s, d|
        @config = YAML.load(d)[@cap.rails_env.to_s]
      }
    end

    def output_file
      @output_file ||= "#{database}-snapshot-#{backup_time}.sql.bz2"
    end

    def output_path
      @output_path ||= File.join(backups_path, output_file)
    end

    def backup_time
      unless @backup_time do
        now = Time.now
        @backup_time = [now.year,now.month,now.day,now.hour,now.min,now.sec].join('-')
      end
      @backup_time
    end

    def dump
      @cap.run "mkdir -p #{backups_path}"
      @cap.run dump_cmd("output_path")
      self
    end

    def restore
      @cap.run import_cmd(last_backup_file)
    end

    def download
      local_file = output_file
      remote_file = output_path
      server = @cap.find_servers(:roles => :db).first

      @cap.sessions[server].sftp.connect {|tsftp| tsftp.download!(remote_file, local_file) }
    end

    def backups_path
      File.join(@cap.shared_path, "db_backups")
    end

    def backups
      @cap.capture("ls -xt #{backups_path}").split.reverse
    end

    def last_backup_file
      File.join(backups_path, backups.last)
    end

  end

  class Local < Base
    def initialize(cap_instance)
      super(cap_instance)
      @config = YAML.load_file(File.join('config', 'database.yml'))[@cap.local_rails_env]
    end
    
    def load(file)
      system("rake db:drop db:create && #{import_cmd(file)} && rake db:migrate") 
    end
  end
  
  def self.check(local_db, remote_db) 
    unless local_db.mysql? && remote_db.mysql?
      raise 'Only mysql on remote and local server is supported' 
    end
  end
end
