#!/usr/bin/env rake

require 'bundler'
Bundler::GemHelper.install_tasks

require 'yard'
namespace :doc do
  YARD::Rake::YardocTask.new do |task|
    task.files   = ['LICENSE.md', 'lib/**/*.rb']
    task.options = ['--markup', 'markdown']
  end
end
