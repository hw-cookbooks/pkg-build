actions :build, :delete
default_action :build

attribute :source, :kind_of => String, :required => true
attribute :ref, :kind_of => String, :default => 'master'
attribute :environment, :kind_of => String, :default => 'production'
attribute :install_dir_prefix, :kind_of => String, :default => '/var/www/rails'
attribute :build_dependencies, :kind_of => Array, :default => []
attribute :dependencies, :kind_of => Array, :default => []
attribute :version, :kind_of => String
attribute :bundle_without_groups, :kind_of => Array, :default => []
attribute :repository, :kind_of => String
attribute :package_name, :kind_of => String
attribute :pre_commands, :kind_of => Array, :default => []
attribute :post_commands, :kind_of => Array, :default => []
