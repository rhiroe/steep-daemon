# frozen_string_literal: true

require_relative "lib/steep/daemon/version"

Gem::Specification.new do |spec|
  spec.name = "steep-daemon"
  spec.version = Steep::Daemon::VERSION
  spec.authors = ["rhiroe"]
  spec.email = ["ride.poke@gmail.com"]

  spec.summary = "Daemon mode for Steep type checker with persistent RBS environment"
  spec.description = "Adds daemon mode to Steep type checker, keeping LSP Server running persistently " \
                     "to avoid expensive RBS environment reloading on each check. " \
                     "Provides 10-100x faster type checking for subsequent runs."
  spec.homepage = "https://github.com/rhiroe/steep-daemon"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rhiroe/steep-daemon"
  spec.metadata["changelog_uri"] = "https://github.com/rhiroe/steep-daemon/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "listen", "~> 3.0"
  spec.add_dependency "steep", ">= 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
