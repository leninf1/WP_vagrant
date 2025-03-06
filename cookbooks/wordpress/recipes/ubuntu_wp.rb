cookbook_file '/tmp/wordpress.zip' do
    source 'wordpress-6.7.2.zip'
    action :create
end

execute "extract_wordpress" do
    command "unzip -q /tmp/wordpress.zip -d /opt/"
    action :run
    notifies :run, 'execute[set_wordpress_permissions]', :immediately
    not_if { ::File.exist?('/opt/wordpress') }
end

execute "set_wordpress_permissions" do
    command "chown -R www-data:www-data /opt/wordpress"
    action :nothing
end

template '/opt/wordpress/wp-config.php' do
    source 'wp-config.php.erb'
    owner 'www-data'
    group 'www-data'
    mode '0644'
    not_if { ::File.exist?('/opt/wordpress/wp-config.php') }
end

template '/etc/apache2/sites-enabled/wordpress.conf' do
    source 'wordpress.conf.erb'
    not_if { ::File.exist?('/etc/apache2/sites-enabled/wordpress.conf') }
end

service "apache2" do
    action :restart
end