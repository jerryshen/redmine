$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"

set :application, "redmine"

ssh_options[:forward_agent] = true
set :rvm_ruby_string, "1.9.3@#{application}"
set :rvm_path, "/home/jerry/.rvm"
set :rvm_bin_path, "/home/jerry/.rvm/bin"
set :rvm_trust_rvmrcs_flag, 1

set :scm, :git
set :repository, "git://github.com/jerryshen/redmine.git"
set :branch, "master"

set :deploy_to, "/home/jerry/apps/#{application}"
set :user, "jerry"
set :use_sudo, false
server "hansay.com", :app, :web, :db, :primary => true
set :deploy_via, :copy

task :configure, :roles => :web do
  run "ln -s #{shared_path}/config/database.yml #{current_release}/config/database.yml"
  run "ln -s #{shared_path}/config/additional_environment.rb #{current_release}/config/additional_environment.rb"
  run "ln -s #{shared_path}/config/configuration.yml #{current_release}/config/configuration.yml"
end

task :trust_rvmrc, :roles => :web do
  run "rvm rvmrc trust #{current_release}"
end

after 'deploy:update_code', :configure
after "deploy:update_code", :trust_rvmrc