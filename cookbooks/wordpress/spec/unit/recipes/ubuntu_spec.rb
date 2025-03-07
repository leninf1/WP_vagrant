require 'spec_helper'

describe 'wordpress::default' do
    let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '20.04').converge(described_recipe) }

    before do
        puts "Running tests for Ubuntu 20.04 platform..."
        stub_command('::File.exist?("/tmp/wordpress.zip")').and_return(false)
        stub_command('::File.exist?("/opt/wordpress")').and_return(false)
        stub_command('::File.exist?("/opt/wordpress/wp-config.php")').and_return(false)
        stub_command('::File.exist?("/etc/httpd/conf.d/wordpress.conf")').and_return(false)
    end

    it 'installs httpd package' do
        expect(chef_run).to install_package('apache2')
    end

    it 'installs php package' do
        expect(chef_run).to install_package('php')
    end

    it 'installs php-mysqlnd package' do
        expect(chef_run).to install_package('php-mysqlnd')
    end

    it 'installs php-json package' do
        expect(chef_run).to install_package('php-json')
    end

    it 'installs unzip package' do
        expect(chef_run).to install_package('unzip')
    end

    it 'installs curl package' do
        expect(chef_run).to install_package('curl')
    end

    it 'creates the info.php file' do
        expect(chef_run).to create_file('/var/www/html/info.php').with_content("<?php\nphpinfo();\n?>")
    end

    it 'enables and starts the apache service' do
        expect(chef_run).to enable_service('apache2')
        expect(chef_run).to start_service('apache2')
    end

    # Test wordpress installation
    describe 'Install wordpress' do
        it { is_expected.to create_cookbook_file('/tmp/wordpress.zip')}
        it { is_expected.to run_execute('extract_wordpress') }
        it { is_expected.to create_template('/opt/wordpress/wp-config.php') }
        it { is_expected.to create_template('/etc/apache2/sites-enabled/wordpress.conf') }
    end

end
