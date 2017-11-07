require 'active_support'
require 'active_record'

def get_env name, default=nil
  ENV[name] || ENV[name.downcase] || default
end

namespace :db do
  desc "prepare environment (utility)"
  task :env do
    require 'bundler'
    env = get_env 'RACK_ENV', 'development'
    Bundler.require :default, env.to_sym
    unless defined?(DB_CONFIG)
      databases = YAML.load_file File.dirname(__FILE__) + '/config/database.yml'
      DB_CONFIG = databases[env]
    end
    puts "loaded config for #{env}"
  end

  desc "connect db (utility)"
  task connect: :env do
    "connecting to #{DB_CONFIG['database']}"
    ActiveRecord::Base.establish_connection DB_CONFIG
  end

  desc "create db for current RACK_ENV"
  task create: :env do
    puts "creating db #{DB_CONFIG['database']}"
    ActiveRecord::Base.establish_connection DB_CONFIG.merge('database' => nil)
    ActiveRecord::Base.connection.create_database DB_CONFIG['database'], charset: 'utf8'
    ActiveRecord::Base.establish_connection DB_CONFIG
  end

  desc 'drop db for current RACK_ENV'
  task drop: :env do
    if get_env('RACK_ENV') == 'production'
      puts "cannot drop production database!"
    else
      puts "dropping db #{DB_CONFIG['database']}"
      ActiveRecord::Base.establish_connection DB_CONFIG.merge('database' => nil)
      ActiveRecord::Base.connection.drop_database DB_CONFIG['database']
    end
  end
  
  desc 'run migrations'
  task migrate: :connect do
    version = get_env 'VERSION'
    version = version ? version.to_i : nil
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate 'db/migrate', version
  end

  desc 'rollback migrations (STEP = 1 by default)'
  task rollback: :connect do
    step = get_env 'STEP'
    step = step ? step.to_i : 1
    ActiveRecord::Migrator.rollback 'db/migrate', step
  end

  desc "show current schema version"
  task version: :connect do
    puts ActiveRecord::Migrator.current_version
  end
end

namespace :metric do
  desc "project statistics"
  task 'stat' do
    puts "\nRuby:"
    stat_files Dir.glob('**/*.rb') - Dir.glob('test/**/*.rb')
  end
end

desc "Run Console"
task :console do |t, args|
  env = ENV['RACK_ENV'] || 'development'
  puts "Loading #{env} environment"
  require File.expand_path("../boot",__FILE__)
  # 必须执行 ARGV.clear，不然 rake 后面的参数会被带到 IRB 里面
  ARGV.clear 
  pry
end

desc "Fetch Pictures"
task :fetch do |t,args|
ENV["RACK_ENV"] = 'production'
  require File.expand_path("../boot",__FILE__)
  File.open('log/fetch.pid','wb'){|f| f.puts Process.pid}
  Dalli.logger.info 'start fetch'
  Spider.fetch_urls(Spider::BASE_URL)

end

desc "Download Pictures"
task :download do |t,args|
  ENV["RACK_ENV"] = 'production'
  require File.expand_path("../boot",__FILE__)
  File.open('log/pic.pid','wb'){|f| f.puts Process.pid}
  Dalli.logger.info 'start'
  Picture.download_pics
end


private
def stat_files fs
  c = 0
  fc = 0
  fs.each do |f|
    fc += 1
    data = File.binread f
    c += data.count "\n"
  end
  puts "files: #{fc}"
  puts "lines: #{c}"
end
