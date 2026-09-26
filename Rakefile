# frozen_string_literal: true

require "bundler/gem_tasks"

# Leave the gem push to GitHub Actions: the tag the release task pushes runs .github/workflows/push_gem.yml, which
# checks the tag with CI and then runs this task there, with the push, to push the gem with trusted publishing
unless ENV["GITHUB_ACTIONS"]
  Rake::Task["release"].clear
  desc "Build the gem and push a tag, which CI pushes the gem for (see .github/workflows/push_gem.yml)"
  task release: %w[build release:guard_clean release:source_control_push]
end

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run specs"
task test: :spec

require "standard/rake"
require "rubocop/rake_task"

RuboCop::RakeTask.new

begin
  require "steep/rake_task"

  Steep::RakeTask.new(:steep)
rescue LoadError
  desc "Run type checker (unavailable on this platform)"
  task :steep do
    warn "Steep is not available on #{RUBY_ENGINE}"
  end
end

# Validate the signatures themselves, which the type checker does not: steep loads them without checking that they
# are valid, so a signature that redeclares a method of a standard library class leaves every call on that class
# unchecked rather than failing. They are validated against the standard libraries sig/manifest.yaml names, which
# are the ones rbs collection loads for code that depends on this gem, so a signature referring to a library the
# manifest leaves out is reported here rather than by whoever depends on it.
desc "Validate the RBS signatures (skipped on Rubies without RBS)"
task :rbs do
  if Gem.loaded_specs.key?("rbs")
    require "yaml"

    libraries = YAML.load_file("sig/manifest.yaml").fetch("dependencies").map { |dependency| dependency.fetch("name") }
    sh "bundle exec rbs -I sig #{libraries.map { |library| "-r #{library}" }.join(" ")} validate"
  else
    warn "RBS is not available on #{RUBY_ENGINE}"
  end
end

desc "Run mutation tests (skipped on Rubies without Mutant)"
task :mutant do
  if Gem.loaded_specs.key?("mutant-rspec")
    sh "bundle exec mutant run"
  else
    warn "Mutant is not available on #{RUBY_ENGINE}"
  end
end

require "yard"

YARD::Rake::YardocTask.new(:yard) do |t|
  t.files = ["lib/**/*.rb"]
  t.options = ["--no-private", "--hide-api", "private"]
end

require "yardstick/rake/measurement"
require "yardstick/rake/verify"

Yardstick::Rake::Measurement.new(:yardstick_measure) do |measurement|
  measurement.output = "doc/coverage.txt"
end

Yardstick::Rake::Verify.new(:yardstick) do |verify|
  verify.threshold = 100
end

desc "Run linters"
task lint: %i[rubocop standard]

task default: %i[spec lint mutant rbs steep yardstick]
