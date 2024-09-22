# config valid for current version and patch releases of Capistrano
lock "~> 3.19.1"

set :application, "pecha_printer"
set :repo_url, "git@github.com:jerefrer/pecha-printer.git"

# Default branch is :main
set :branch, 'main'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/deploy/pecha_printer'

# Default value for :linked_files is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'tmp/webpacker', 'vendor/javascript', '.bundle', 'public/system', 'public/uploads', 'storage'

# Only keep the last 5 releases to save disk space
set :keep_releases, 5

set :ssh_options, forward_agent: true

# Ensure submodules are initialized and updated
# after 'deploy:updating', 'deploy:git_submodules'

# namespace :deploy do
#   task :git_submodules do
#     on roles(:app) do
#       within release_path.join('lib/generate-printable-pecha/') do
#         execute :git, 'submodule init'
#         execute :git, 'submodule update'
#       end
#     end
#   end
# end

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
