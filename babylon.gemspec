# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{babylon}
  s.version = "0.0.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["julien Genestoux"]
<<<<<<< HEAD:babylon.gemspec
  s.date = %q{2009-03-29}
=======
  s.date = %q{2009-03-30}
>>>>>>> slowly migrating to templater:babylon.gemspec
  s.default_executable = %q{babylon}
  s.email = %q{julien.genestoux@gmail.com}
  s.executables = ["babylon"]
  s.extra_rdoc_files = ["README.rdoc", "LICENSE"]
<<<<<<< HEAD:babylon.gemspec
  s.files = ["bin/babylon", "lib/babylon.rb", "lib/babylon/base/controller.rb", "lib/babylon/base/stanza.rb", "lib/babylon/base/iq.rb", "lib/babylon/base/message.rb", "lib/babylon/base/presence.rb", "lib/babylon/base/view.rb", "lib/babylon/client_connection.rb", "lib/babylon/component_connection.rb", "lib/babylon/router/dsl.rb", "lib/babylon/router.rb", "lib/babylon/runner.rb", "lib/babylon/xmpp_connection.rb", "lib/babylon/xmpp_parser.rb", "lib/babylon/xpath_helper.rb", "LICENSE", "Rakefile", "README.rdoc", "templates/babylon/app/controllers/README.rdoc", "templates/babylon/app/models/README.rdoc", "templates/babylon/app/views/README.rdoc", "templates/babylon/config/boot.rb", "templates/babylon/config/config.yaml", "templates/babylon/config/dependencies.rb", "templates/babylon/config/routes.rb", "templates/babylon/config/initializers/README.rdoc"]
=======
  s.files = ["bin/babylon", "lib/babylon.rb", "lib/babylon/base/controller.rb", "lib/babylon/base/view.rb", "lib/babylon/client_connection.rb", "lib/babylon/component_connection.rb", "lib/babylon/router/dsl.rb", "lib/babylon/router.rb", "lib/babylon/runner.rb", "lib/babylon/generator.rb", "lib/babylon/xmpp_connection.rb", "lib/babylon/xmpp_parser.rb", "lib/babylon/xpath_helper.rb", "LICENSE", "Rakefile", "README.rdoc", "templates/babylon/app/controllers/controller.rb", "templates/babylon/config/boot.rb", "templates/babylon/config/config.yaml", "templates/babylon/config/dependencies.rb", "templates/babylon/config/routes.rb", "templates/babylon/script/component"]
>>>>>>> slowly migrating to templater:babylon.gemspec
  s.has_rdoc = true
  s.homepage = %q{http://github.com/julien51/babylon}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.requirements = ["eventmachine", "yaml", "fileutils", "log4r", "nokogiri"]
  s.rubyforge_project = %q{babylon}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Babylon is a framework to create EventMachine based XMPP External Components in Ruby.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
