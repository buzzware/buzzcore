# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{buzzcore}
  s.version = "0.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["buzzware"]
  s.date = %q{2009-10-06}
  s.description = %q{buzzcore is the ruby core library developed and used by Buzzware Solutions.}
  s.email = %q{contact@buzzware.com.au}
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
     "buzzcore.gemspec",
     "buzzcore.vpj",
     "buzzcore.vpw",
     "lib/buzzcore.rb",
     "lib/buzzcore.rb",
     "lib/buzzcore/config.rb",
     "lib/buzzcore/database_utils.rb",
     "lib/buzzcore/enum.rb",
     "lib/buzzcore/extend_base_classes.rb",
     "lib/buzzcore/html_utils.rb",
     "lib/buzzcore/logging.rb",
     "lib/buzzcore/misc_utils.rb",
     "lib/buzzcore/require_paths.rb",
     "lib/buzzcore/shell_extras.rb",
     "lib/buzzcore/string_utils.rb",
     "lib/buzzcore/text_doc.rb",
     "lib/buzzcore/thread_utils.rb",
     "lib/buzzcore/xml_utils.rb",
     "lib/buzzcore_dev.rb",
     "test/buzzcore_test.rb",
     "test/config_test.rb",
     "test/credentials_test.rb",
     "test/shell_test.rb",
     "test/test_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/buzzware/buzzcore}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{buzzcore is the ruby core library developed and used by Buzzware Solutions.}
  s.test_files = [
    "test/buzzcore_test.rb",
     "test/config_test.rb",
     "test/credentials_test.rb",
     "test/shell_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    else
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
  end
end
