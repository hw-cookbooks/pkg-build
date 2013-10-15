def load_current_resource
  unless(new_resource.package_name)
    new_resource.package_name new_resource.name.gsub(%r{[^A-Za-z0-9\-_]}, '')
  end
  new_resource.bundle_without_groups new_resource.bundle_without_groups | %w(test development)
  new_resource.version Time.now.to_i.to_s unless new_resource.version
end

def bundle_without_groups
  new_resource.bundle_without_groups.join(' ')
end

action :build do

  # cache attributes
  cache = Mash.new
  %w(name source ref environment version install_dir_prefix dependencies repository).each do |key|
    cache[key] = new_resource.send(key)
  end
  
  # Install build dependencies
  new_resource.build_dependencies.each do |pkg|
    package pkg
  end

  gem_package 'bundler'

  build_commands = [
    {
      :command => "bundle install --path ./vendor --quiet --without=#{bundle_without_groups} --binstubs",
      :environment => {'LANG' => 'en_US.UTF-8', 'LC_ALL' => 'en_US.UTF-8'}
    },
    new_resource.pre_commands,
    'cp config/application.rb config/.application.rb.bak',
    "echo '' >> config/application.rb",
    "echo 'Rails.application.class.configure{config.assets.initialize_on_precompile=false}' >> config/application.rb",
    "./bin/rake assets:precompile RAILS_ENV=#{cache[:environment]} RAILS_GROUPS=assets",
    'mv config/.application.rb.bak config/application.rb',
    new_resource.post_commands,
    # TODO: add revision file with git sha
    "mkdir -p #{::File.join('$PKG_DIR', cache[:install_dir_prefix], cache[:name], cache[:version])}",
    "rsync -a --exclude=.git --exclude=log ./ #{::File.join('$PKG_DIR', cache[:install_dir_prefix], cache[:name], 'releases', cache[:version])}"
  ].flatten.compact

  if(new_resource.source.start_with?('/') && ::File.directory?(new_source.source))
    build_type = :builder_dir
  else
    build_type = :builder_git
  end
  
  # Fetch and build
  send(build_type, new_resource.package_name) do
    if(build_type == :builder_git)
      repository cache[:source]
      reference cache[:ref]
    else
      custom_cwd cache[:source]
    end
    commands build_commands
    creates ::File.join(node[:builder][:build_dir], cache[:name], cache[:ref], 'public/assets')
  end

  fpm_tng_package [node[:pkg_build][:pkg_prefix], new_resource.environment, new_resource.package_name].compact.join('-') do
    output_type 'deb'
    description "#{new_resource.name} Application"
    depends cache[:dependencies] unless cache[:dependencies].empty?
    version cache[:version]
    chdir ::File.join(node[:builder][:packaging_dir], cache[:name], cache[:ref])
    repository cache[:repository] if cache[:repository]
  end
end

action :delete do
end
