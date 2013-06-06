require "pyenv"
require "pyenv/rack"
require "jenkins/rack"

class PyenvDescriptor < Jenkins::Model::DefaultDescriptor
  include Jenkins::RackSupport
  def call(env)
    Pyenv::RackApplication.new.call(env)
  end
end

class PyenvWrapper < Jenkins::Tasks::BuildWrapper
  TRANSIENT_INSTANCE_VARIABLES = [:build, :launcher, :listener]
  class << self
    def transient?(symbol)
      # return true for a variable which should not be serialized
      TRANSIENT_INSTANCE_VARIABLES.include?(symbol)
    end
  end

  describe_as Java.hudson.tasks.BuildWrapper, :with => PyenvDescriptor
  display_name "pyenv build wrapper"

  # FIXME: these values should be shared between views/pyenv_wrapper/config.erb
  DEFAULT_VERSION = "2.7.5"
  DEFAULT_PIP_LIST = "tox"
  DEFAULT_IGNORE_LOCAL_VERSION = false
  DEFAULT_PYENV_ROOT = "$HOME/.pyenv"
  DEFAULT_PYENV_REPOSITORY = "git://github.com/yyuu/pyenv.git"
  DEFAULT_PYENV_REVISION = "master"

  attr_reader :build
  attr_reader :launcher
  attr_reader :listener

  attr_accessor :version
  attr_accessor :pip_list
  attr_accessor :ignore_local_version
  attr_accessor :pyenv_root
  attr_accessor :pyenv_repository
  attr_accessor :pyenv_revision

  # The default values should be set on both instantiation and deserialization.
  def initialize(attrs={})
    from_hash(attrs)
  end

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

  private
  def from_hash(hash)
    @version = attribute(hash.fetch("version", @version), DEFAULT_VERSION)
    @pip_list = attribute(hash.fetch("pip_list", @pip_list), DEFAULT_PIP_LIST)
    @ignore_local_version = attribute(hash.fetch("ignore_local_version", @ignore_local_version), DEFAULT_IGNORE_LOCAL_VERSION)
    @pyenv_root = attribute(hash.fetch("pyenv_root", @pyenv_root), DEFAULT_PYENV_ROOT)
    @pyenv_repository = attribute(hash.fetch("pyenv_repository", @pyenv_repository), DEFAULT_PYENV_REPOSITORY)
    @pyenv_revision = attribute(hash.fetch("pyenv_revision", @pyenv_revision), DEFAULT_PYENV_REVISION)
  end

  # Jenkins may return empty string as attribute value which we must ignore
  def attribute(value, default_value=nil)
    str = value.to_s
    not(str.empty?) ? str : default_value
  end
end
