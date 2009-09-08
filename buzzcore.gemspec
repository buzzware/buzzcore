# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{buzzcore}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gary McGhee"]
  s.date = %q{2009-09-08}
  s.description = %q{buzzcore is the ruby core library developed and used by Buzzware Solutions.}
  s.email = %q{contact@buzzware.com.au}
  s.extra_rdoc_files = ["README.md", "LICENSE"]
  s.files = [
		"API.txt", 
		"History.txt", 
		"README.md", 
		"VERSION.yml", 
		"lib/buzzcore",
		"lib/buzzcore.rb",
		"LICENSE"
	]
  s.has_rdoc = false
  s.homepage = %q{http://github.com/buzzware/buzzcore}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{buzzcore}
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{buzzcore is the ruby core library developed and used by Buzzware Solutions.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    #if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    #  s.add_runtime_dependency(%q<mime-types>, [">= 1.15"])
    #  s.add_runtime_dependency(%q<diff-lcs>, [">= 1.1.2"])
    #else
    #  s.add_dependency(%q<mime-types>, [">= 1.15"])
    #  s.add_dependency(%q<diff-lcs>, [">= 1.1.2"])
    #end
  else
    #s.add_dependency(%q<mime-types>, [">= 1.15"])
    #s.add_dependency(%q<diff-lcs>, [">= 1.1.2"])
  end
end
