if(node[:pkg_build][:isolate])

  include_recipe 'pkg-build::ruby'
  
  node[:pkg_build][:rails].each do |name, options|

    ruby_version = options[:ruby_version] || '1.9.3'

    coms = Array(options[:build_dependencies]).flatten.map do |pkg|
      "apt-get install -q -y #{pkg}"
    end
    
    lxc_container "ubuntu_1204-ruby#{ruby_version}-#{name}" do
      action :create
      clone "ubuntu_1204-ruby#{ruby_version}"
      default_fstab false
      
      initialize_commands [
        "apt-get update",
        "gem install --no-ri --no-rdoc bundler"
      ] + coms
    end
    
    pkg_build_isolate name do
      container "ubuntu_1204-ruby#{ruby_version}-#{name}"
      attributes(
        :pkg_build => {
          :rails => node[:pkg_build][:rails]
        }
      )
      run_list ['recipe[pkg-build::rails]']
    end

  end
else
  include_recipe 'pkg-build::deps'
  
  node[:pkg_build][:rails].each do |name, options|
    if(options[:extra_recipes])
      Array(options[:extra_recipes].flatten).each do |recipe_name|
        include_recipe recipe_name
      end
    end
    pkg_build_rails name do
      options.each do |k,v|
        send(k, v)
      end
    end
  end
  
end
