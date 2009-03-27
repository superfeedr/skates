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
    gem.requirements = ["eventmachine", "yaml", "fileutils", "log4r", "nokogiri"]
    gem.executables = "babylon"
    gem.files = ["bin/babylon", "lib/babylon.rb", "lib/babylon/base/controller.rb", "lib/babylon/base/view.rb", "lib/babylon/client_connection.rb", "lib/babylon/component_connection.rb", "lib/babylon/router/dsl.rb", "lib/babylon/router.rb", "lib/babylon/runner.rb", "lib/babylon/xmpp_connection.rb", "lib/babylon/xmpp_parser.rb", "lib/babylon/xpath_helper.rb", "LICENSE", "Rakefile", "README.rdoc", "templates/babylon/app/controllers/README.rdoc", "templates/babylon/app/models/README.rdoc", "templates/babylon/app/views/README.rdoc", "templates/babylon/config/boot.rb", "templates/babylon/config/config.yaml", "templates/babylon/config/dependencies.rb", "templates/babylon/config/routes.rb", "templates/babylon/config/initializers/README.rdoc"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'babylon'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
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
    spec.rcov = true
    spec.rcov_opts = []
  end
rescue LoadError
  task :spec do
    abort "Rspec is not available. In order to run rspec, you must: sudo gem install rspec"
  end
end

begin
  require 'rcov/verifytask'
  desc "Verfiy Rcov level"
  RCov::VerifyTask.new('rcov:verify') do |spec|
  end
rescue LoadError
  task :spec do
    abort "Rspec is not available. In order to run rspec, you must: sudo gem install rspec"
  end
end



task :install => :build

task :default => :test
