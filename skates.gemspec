# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{skates}
  s.version = "0.2.13"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["julien Genestoux"]
  s.date = %q{2010-02-05}
  s.default_executable = %q{skates}
  s.email = %q{julien.genestoux@gmail.com}
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
  s.homepage = %q{http://github.com/julien51/skates}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.requirements = ["eventmachine", "yaml", "fileutils", "log4r", "nokogiri", "superfeedr-sax-machine", "templater", "optparse", "digest/sha1", "base64", "resolv"]
  s.rubyforge_project = %q{skates}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Skates is a framework to create EventMachine based XMPP External Components in Ruby.}
  s.test_files = [
    "spec/bin/skates_spec.rb",
     "spec/em_mock.rb",
     "spec/lib/skates/base/controller_spec.rb",
     "spec/lib/skates/base/stanza_spec.rb",
     "spec/lib/skates/base/view_spec.rb",
     "spec/lib/skates/client_connection_spec.rb",
     "spec/lib/skates/component_connection_spec.rb",
     "spec/lib/skates/generator_spec.rb",
     "spec/lib/skates/router/dsl_spec.rb",
     "spec/lib/skates/router_spec.rb",
     "spec/lib/skates/runner_spec.rb",
     "spec/lib/skates/xmpp_connection_spec.rb",
     "spec/lib/skates/xmpp_parser_spec.rb",
     "spec/spec_helper.rb",
     "test/skates_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.10"])
      s.add_runtime_dependency(%q<log4r>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.4.1"])
      s.add_runtime_dependency(%q<superfeedr-sax-machine>, [">= 0.0.23"])
      s.add_runtime_dependency(%q<templater>, [">= 0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
      s.add_dependency(%q<log4r>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 1.4.1"])
      s.add_dependency(%q<superfeedr-sax-machine>, [">= 0.0.23"])
      s.add_dependency(%q<templater>, [">= 0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
    s.add_dependency(%q<log4r>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 1.4.1"])
    s.add_dependency(%q<superfeedr-sax-machine>, [">= 0.0.23"])
    s.add_dependency(%q<templater>, [">= 0"])
  end
end

