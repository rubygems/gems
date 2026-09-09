require "bundler/gem_tasks"

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run specs"
task test: :spec

require "standard/rake"
require "rubocop/rake_task"

RuboCop::RakeTask.new

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
  verify.threshold = 79.8
end

desc "Run linters"
task lint: %i[rubocop standard]

task default: %i[spec lint yardstick]
