require "java"
require "pyenv"
require "pyenv/rack"
require "jenkins/rack"

class PyenvDescriptor < Jenkins::Model::DefaultDescriptor
  DEFAULT_VERSION = "3.4.1"
  DEFAULT_PIP_LIST = "tox"
  DEFAULT_IGNORE_LOCAL_VERSION = false
  DEFAULT_PYENV_ROOT = "$HOME/.pyenv"
  DEFAULT_PYENV_REPOSITORY = "https://github.com/yyuu/pyenv.git"
  DEFAULT_PYENV_REVISION = "master"

  include Jenkins::RackSupport
  def call(env)
    Pyenv::RackApplication.new.call(env)
  end
end

class PyenvWrapper < Jenkins::Tasks::BuildWrapper
  TRANSIENT_INSTANCE_VARIABLES = [:build, :launcher, :listener]
  class << self
    def transient?(x)
      # return true for a variable which should not be serialized
      TRANSIENT_INSTANCE_VARIABLES.include?(x.to_s.to_sym)
    end
  end

  describe_as Java.hudson.tasks.BuildWrapper, :with => PyenvDescriptor
  display_name "pyenv build wrapper"

  # The default values should be set on both instantiation and deserialization.
  def initialize(attrs={})
    from_hash(attrs)
  end

  attr_reader :build
  attr_reader :launcher
  attr_reader :listener

  attr_accessor :version
  attr_accessor :pip_list
  attr_accessor :ignore_local_version
  attr_accessor :pyenv_root
  attr_accessor :pyenv_repository
  attr_accessor :pyenv_revision

  # Will be invoked by jruby-xstream after deserialization from configuration file.
  def read_completed()
    from_hash({})
  end

  def setup(build, launcher, listener)
    @build = build
    @launcher = launcher
    @listener = listener
    Pyenv::Environment.new(self).setup!
  end

  def to_hash()
    {
      "version" => @version,
      "pip_list" => @pip_list,
      "ignore_local_version" => @ignore_local_version,
      "pyenv_root" => @pyenv_root,
      "pyenv_repository" => @pyenv_repository,
      "pyenv_revision" => @pyenv_revision,
    }
  end

  private
  def from_hash(hash)
    @version = string(hash.fetch("version", @version), PyenvDescriptor::DEFAULT_VERSION)
    @pip_list = string(hash.fetch("pip_list", @pip_list), PyenvDescriptor::DEFAULT_PIP_LIST)
    @ignore_local_version = boolean(hash.fetch("ignore_local_version", @ignore_local_version), PyenvDescriptor::DEFAULT_IGNORE_LOCAL_VERSION)
    @pyenv_root = string(hash.fetch("pyenv_root", @pyenv_root), PyenvDescriptor::DEFAULT_PYENV_ROOT)
    @pyenv_repository = string(hash.fetch("pyenv_repository", @pyenv_repository), PyenvDescriptor::DEFAULT_PYENV_REPOSITORY)
    @pyenv_revision = string(hash.fetch("pyenv_revision", @pyenv_revision), PyenvDescriptor::DEFAULT_PYENV_REVISION)
  end

  # Jenkins may return empty string as attribute value which we must ignore
  def string(value, default_value=nil)
    s = value.to_s
    if s.empty?
      default_value
    else
      s
    end
  end

  def boolean(value, default_value=false)
    if FalseClass === value or TrueClass === value
      value
    else
      # pyenv plugin (<= 0.0.4) stores boolean values as String
      case value.to_s
      when /false/i then false
      when /true/i  then true
      else
        default_value
      end
    end
  end
end
