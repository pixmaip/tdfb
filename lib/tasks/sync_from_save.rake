namespace :db do
  task :sync_from_save, [:password, :user] => :environment do |_, args|
    check_user(args[:user])
    ask_confirmation
    backup_current_base
    path = fetch_database_on_gmail(args[:password])
    remplace_database(path)
  end

  def check_user(user)
    fail 'Tu n\'est pas celui que tu crois être' unless user == ENV['USER']
  end

  def ask_confirmation
    puts 'Ne jamais jamais faire ca sur l\'ordi du BôB, taper "oui" pour continuer'
    STDOUT.flush
    input = STDIN.gets.chomp
    fail 'Ouf tu as failli faire une grosse bêtise ...' unless 'oui'.casecmp(input) == 0
  end

  def backup_current_base
    conf = Rails.configuration.database_configuration[Rails.env]
    backup_path = Rails.root.to_s + '/tmp/Backup_' + Time.now.utc.iso8601
    puts 'Backup de la base actuelle ...'
    `mysqldump -u#{conf['username']} -p#{conf['password']} #{conf['database']} > #{backup_path}`
    puts 'Backup de la base réussi'
  end

  def fetch_database_on_gmail(password)
    require 'gmail'
    path = ''
    puts 'Connexion à Gmail ...'
    Gmail.new('bobar.save@gmail.com', password) do |gmail|
      tdb_dump = gmail.inbox.emails.last.attachments.first
      path = Rails.root.to_s + '/' + tdb_dump.filename
      file = File.new(path, 'w+', encoding: 'ascii-8bit')
      file << tdb_dump.decoded
      file.close
    end
    puts 'Connexion à Gmail réussie'
    path
  end

  def remplace_database(path)
    conf = Rails.configuration.database_configuration[Rails.env]
    puts 'Remplacement de la base ...'
    `gzip -dc #{path} | mysql -u#{conf['username']} -p#{conf['password']} #{conf['database']}`
    puts 'Remplacement de la base réussie !'
    `rm #{path}`
  end
end