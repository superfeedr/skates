# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "skates"
  s.version = "0.5.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["julien Genestoux"]
  s.date = "2012-07-10"
  s.email = "julien.genestoux@gmail.com"
  s.executables = ["skates"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "bin/skates",
    "lib/skates.rb",
    "lib/skates/base/controller.rb",
    "lib/skates/base/stanza.rb",
    "lib/skates/base/view.rb",
    "lib/skates/client_connection.rb",
    "lib/skates/component_connection.rb",
    "lib/skates/ext/array.rb",
    "lib/skates/generator.rb",
    "lib/skates/router.rb",
    "lib/skates/router/dsl.rb",
    "lib/skates/runner.rb",
    "lib/skates/xmpp_connection.rb",
    "lib/skates/xmpp_parser.rb",
    "templates/skates/Gemfile",
    "templates/skates/app/controllers/controller.rb",
    "templates/skates/app/stanzas/stanza.rb",
    "templates/skates/app/views/view.rb",
    "templates/skates/config/boot.rb",
    "templates/skates/config/config.yaml",
    "templates/skates/config/dependencies.rb",
    "templates/skates/config/routes.rb",
    "templates/skates/log/development.log",
    "templates/skates/log/production.log",
    "templates/skates/log/test.log",
    "templates/skates/script/component",
    "templates/skates/tmp/pids/README"
  ]
  s.homepage = "http://github.com/julien51/skates"
  s.require_paths = ["lib"]
  s.requirements = ["bundler", "eventmachine", "yaml", "fileutils", "log4r", "nokogiri", "optparse", "digest/sha1", "base64", "resolv", "utf8cleaner"]
  s.rubyforge_project = "skates"
  s.rubygems_version = "1.8.17"
  s.summary = "Skates is a framework to create EventMachine based XMPP External Components in Ruby."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.10"])
      s.add_runtime_dependency(%q<log4r>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, ["= 1.4.4"])
      s.add_runtime_dependency(%q<utf8cleaner>, [">= 0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
      s.add_dependency(%q<log4r>, [">= 0"])
      s.add_dependency(%q<nokogiri>, ["= 1.4.4"])
      s.add_dependency(%q<utf8cleaner>, [">= 0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
    s.add_dependency(%q<log4r>, [">= 0"])
    s.add_dependency(%q<nokogiri>, ["= 1.4.4"])
    s.add_dependency(%q<utf8cleaner>, [">= 0"])
  end
end

