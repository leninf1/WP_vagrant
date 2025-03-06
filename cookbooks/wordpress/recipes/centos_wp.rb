directory "/opt/" do
    owner "root"
    group "root"
end

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
    command "chmod -R 755 /opt/wordpress/"
    action :nothing
end

template '/opt/wordpress/wp-config.php' do
    source 'wp-config.php.erb'
    mode '0644'
    not_if { ::File.exist?('/opt/wordpress/wp-config.php') }
end

template '/etc/httpd/conf.d/wordpress.conf' do
    source 'wordpress.conf.erb'
    not_if { ::File.exist?('/etc/httpd/conf.d/wordpress.conf') }
end

service "httpd" do
    action :restart
end