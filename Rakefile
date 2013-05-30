require "rake/testtask"
require "rake/clean"

## jpi ##
require "jenkins/rake"
Jenkins::Rake.install_tasks

## rspec ##
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
