require "bundler/gem_tasks"

# Override the release task to skip the gem push, which is handled by GitHub Actions with attestations
# when a GitHub release is created (see .github/workflows/push_gem.yml)
Rake::Task["release"].clear
desc "Build the gem and create a tag (the gem push is handled by CI)"
task release: %w[build release:guard_clean release:source_control_push]

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

desc "Run mutation tests (skipped on Rubies without Mutant)"
task :mutant do
  if Gem.loaded_specs.key?("mutant-rspec")
    sh "bundle exec mutant run"
  else
    warn "Mutant is not available on Ruby #{RUBY_VERSION}"
  end
end

require "yard"

YARD::Rake::YardocTask.new(:yard) do |t|
  t.files = ["lib/**/*.rb"]
  t.options = ["--no-private"]
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

task default: %i[spec lint mutant steep yardstick]
