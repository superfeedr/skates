require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "babylon"
    gem.summary = %Q{Babylon is a framework to create EventMachine based XMPP External Components in Ruby.}
    gem.email = "julien.genestoux@gmail.com"
    gem.homepage = "http://github.com/julien51/babylon"
    gem.authors = ["julien Genestoux"]

    gem.add_dependency('eventmachine')
    gem.add_dependency('log4r')
    gem.add_dependency('nokogiri', ">= 1.3.3")
    gem.add_dependency('julien51-sax-machine', ">= 0.0.20")
    gem.add_dependency('templater')
    gem.add_dependency('daemons')
    gem.requirements = ["eventmachine", "yaml", "fileutils", "log4r", "nokogiri", "julien51-sax-machine", "templater", "daemons", "optparse", "digest/sha1", "base64", "resolv", "activesupport"]
    gem.executables = "babylon"
    gem.files = [ "bin/babylon", 
                  "lib/babylon.rb", 
                  "lib/babylon/base/controller.rb", 
                  "lib/babylon/base/view.rb", 
                  "lib/babylon/base/stanza.rb", 
                  "lib/babylon/client_connection.rb", 
                  "lib/babylon/component_connection.rb", 
                  "lib/babylon/router/dsl.rb", 
                  "lib/babylon/router.rb", 
                  "lib/babylon/runner.rb", 
                  "lib/babylon/generator.rb", 
                  "lib/babylon/xmpp_connection.rb", 
                  "lib/babylon/xmpp_parser.rb", 
                  "lib/babylon/xpath_helper.rb", 
                  "LICENSE", 
                  "Rakefile", 
                  "README.rdoc", 
                  "templates/babylon/app/controllers/controller.rb", 
                  "templates/babylon/app/views/view.rb", 
                  "templates/babylon/app/stanzas/stanza.rb", 
                  "templates/babylon/config/boot.rb", 
                  "templates/babylon/config/config.yaml", 
                  "templates/babylon/config/dependencies.rb", 
                  "templates/babylon/config/routes.rb", 
                  "templates/babylon/script/component",
                  "templates/babylon/log/test.log",
                  "templates/babylon/log/development.log",
                  "templates/babylon/log/production.log",
                  "templates/babylon/tmp/pids/README"
                  ]
    gem.rubyforge_project = 'babylon'
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'Babylon : a framework to create EventMachine based XMPP External Components in Ruby.'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << '--line-numbers'
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = false
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

begin
  require 'spec/rake/spectask'
  desc "Run all Spec"
  Spec::Rake::SpecTask.new('spec') do |spec|
    spec.spec_files = FileList['spec/**/*.rb']
    spec.verbose = true
    spec.warning = false
    spec.rcov = true
  end
rescue LoadError
  task :spec do
    abort "Rspec is not available. In order to run rspec, you must: sudo gem install rspec"
  end
end

begin
  require 'spec/rake/verify_rcov'

  RCov::VerifyTask.new(:verify_rcov => 'spec') do |t|
    t.threshold = 100.0
    t.index_html = 'coverage/index.html'
  end
rescue LoadError
  task :spec do
    abort "Rcov is not available. In order to run rcov, you must: sudo gem install rcov"
  end
end

# These are Rubyforge tasks
begin
  require 'rake/contrib/sshpublisher'
  namespace :rubyforge do

    desc "Release gem and RDoc documentation to RubyForge"
    task :release => ["rubyforge:release:gem", "rubyforge:release:docs"]

    namespace :release do
      desc "Publish RDoc to RubyForge."
      task :docs => [:rdoc] do
        config = YAML.load(
            File.read(File.expand_path('~/.rubyforge/user-config.yml'))
        )

        host = "#{config['username']}@rubyforge.org"
        remote_dir = "/var/www/gforge-projects/babylon"
        local_dir = 'rdoc'

        Rake::SshDirPublisher.new(host, remote_dir, local_dir).upload
      end
    end
  end
rescue LoadError
  puts "Rake SshDirPublisher is unavailable or your rubyforge environment is not configured."
end


task :install => :build

task :default => :test
