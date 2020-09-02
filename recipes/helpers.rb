if node['pkg_build']['reprepro']
  template '/usr/local/bin/pkg-build-remover' do
    source 'pkg-build-remover.erb'
    mode '755'
  end
end
