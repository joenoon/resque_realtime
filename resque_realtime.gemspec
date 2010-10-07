# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{resque_realtime}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joe Noon"]
  s.date = %q{2010-10-07}
  s.description = %q{Resque jobs that work together with the resque_realtime node.js socket.io server.}
  s.email = %q{joenoon@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "init.rb",
     "lib/resque_realtime.rb",
     "lib/resque_realtime/base.rb",
     "lib/resque_realtime/connected.rb",
     "lib/resque_realtime/disconnected.rb",
     "lib/resque_realtime/helpers.rb",
     "lib/resque_realtime/server_offline.rb",
     "lib/resque_realtime/server_online.rb",
     "test/helper.rb",
     "test/test_resque_realtime.rb"
  ]
  s.homepage = %q{http://github.com/joenoon/resque_realtime}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Resque jobs that work together with the resque_realtime node.js socket.io server}
  s.test_files = [
    "test/helper.rb",
     "test/test_resque_realtime.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.3.8"])
      s.add_runtime_dependency(%q<resque>, [">= 1.9.10"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.3.8"])
      s.add_dependency(%q<resque>, [">= 1.9.10"])
      s.add_dependency(%q<shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.3.8"])
    s.add_dependency(%q<resque>, [">= 1.9.10"])
    s.add_dependency(%q<shoulda>, [">= 0"])
  end
end
