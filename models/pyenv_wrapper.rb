require 'stringio'
require 'shellwords'

class PyenvWrapper < Jenkins::Tasks::BuildWrapper
  TRANSIENT_INSTANCE_VARIABLES = [:launcher]
  class << self
    def transient?(symbol)
      # return true for a variable which should not be serialized
      TRANSIENT_INSTANCE_VARIABLES.include?(symbol)
    end
  end

  display_name "pyenv build wrapper"

  # FIXME: these values should be shared between views/pyenv_wrapper/config.erb
  DEFAULT_VERSION = "2.7.5"
  DEFAULT_PIP_LIST = "tox"
  DEFAULT_IGNORE_LOCAL_VERSION = false
  DEFAULT_PYENV_ROOT = "$HOME/.pyenv"
  DEFAULT_PYENV_REPOSITORY = "git://github.com/yyuu/pyenv.git"
  DEFAULT_PYENV_REVISION = "master"

  attr_accessor :version
  attr_accessor :pip_list
  attr_accessor :ignore_local_version
  attr_accessor :pyenv_root
  attr_accessor :pyenv_repository
  attr_accessor :pyenv_revision

  # The default values should be set on both instantiation and deserialization.
  def initialize(attrs={})
    load_attributes!(attrs)
  end

  # Will be invoked by jruby-xstream after deserialization from configuration file.
  def read_completed()
    load_attributes!
  end

  def setup(build, launcher, listener)
    @launcher = launcher
    unless directory_exists?(pyenv_root)
      listener << "Install pyenv\n"
      run(scm_checkout(pyenv_repository, pyenv_revision, pyenv_root), {out: listener})
    end

    pyenv_bin = "#{pyenv_root}/bin/pyenv"

    unless @ignore_local_version
      # Respect local Python version if defined in the workspace
      local_version = capture("cd #{build.workspace.to_s.shellescape} && #{pyenv_bin.shellescape} local 2>/dev/null || true").strip
      @version = local_version unless local_version.empty?
    end

    # To avoid starting multiple build jobs, acquire lock during installation
    synchronize("#{pyenv_root}.lock") do
      versions = capture("PYENV_ROOT=#{pyenv_root.shellescape} #{pyenv_bin.shellescape} versions --bare").strip.split
      unless versions.include?(@version)
        # To update definitions, update pyenv before installing python
        listener << "Update pyenv\n"
        run(scm_sync(pyenv_repository, pyenv_revision, pyenv_root), {out: listener})
        listener << "Install #{@version}\n"
        run("PYENV_ROOT=#{pyenv_root.shellescape} #{pyenv_bin.shellescape} install #{@version.shellescape}", {out: listener})
      end

      # Run rehash everytime before invoking pip
      run("PYENV_ROOT=#{pyenv_root.shellescape} #{pyenv_bin.shellescape} rehash", {out: listener})

      pip_bin = "#{pyenv_root}/shims/pip"
      list = capture("PYENV_ROOT=#{pyenv_root.shellescape} PYENV_VERSION=#{@version.shellescape} #{pip_bin.shellescape} list").strip.split
      (@pip_list || 'tox').split(',').each do |pip|
        unless list.include? pip
          listener << "Install #{pip}\n"
          run("PYENV_ROOT=#{pyenv_root.shellescape} PYENV_VERSION=#{@version.shellescape} #{pip_bin.shellescape} install #{pip.shellescape}", {out: listener})
        end
      end

      # Run rehash everytime after invoking pip
      run("PYENV_ROOT=#{pyenv_root.shellescape} #{pyenv_bin.shellescape} rehash", {out: listener})
    end

    build.env["PYENV_ROOT"] = pyenv_root
    build.env['PYENV_VERSION'] = @version
    # Set ${PYENV_ROOT}/bin in $PATH to allow invoke pyenv from shell
    build.env["PATH+PYENV_BIN"] = "#{pyenv_root}/bin"
    # Set ${PYENV_ROOT}/bin in $PATH to allow invoke binstubs from shell
    build.env["PATH+PYENV_SHIMS"] = "#{pyenv_root}/shims"
  end

  private
  def directory_exists?(path)
    execute("test -d #{path}") == 0
  end

  def capture(command, options={})
    out = StringIO.new
    run(command, options.merge({out: out}))
    out.rewind
    out.read
  end

  def run(command, options={})
    if execute(command, options) != 0
      raise(RuntimeError.new("failed: #{command.inspect}"))
    end
  end

  def execute(command, options={})
    @launcher.execute("bash", "-c", command, options)
  end

  def scm_checkout(repository, revision, destination)
    execute = []
    execute << "git clone #{repository.shellescape} #{destination.shellescape}"
    execute << "cd #{destination.shellescape}"
    execute << "git checkout #{revision.shellescape}"
    execute.join(" && ")
  end

  def scm_sync(repository, revision, destination)
    execute = []
    execute << "cd #{destination.shellescape}"
    execute << "git fetch"
    execute << "git fetch --tags"
    execute << "git reset --hard #{revision}"
    execute.join(" && ")
  end

  def load_attributes!(attrs={})
    @version = attribute(attrs.fetch("version", @version), DEFAULT_VERSION)
    @pip_list = attribute(attrs.fetch("pip_list", @pip_list), DEFAULT_PIP_LIST)
    @ignore_local_version = attribute(attrs.fetch("ignore_local_version", @ignore_local_version), DEFAULT_IGNORE_LOCAL_VERSION)
    @pyenv_root = attribute(attrs.fetch("pyenv_root", @pyenv_root), DEFAULT_PYENV_ROOT)
    @pyenv_repository = attribute(attrs.fetch("pyenv_repository", @pyenv_repository), DEFAULT_PYENV_REPOSITORY)
    @pyenv_revision = attribute(attrs.fetch("pyenv_revision", @pyenv_revision), DEFAULT_PYENV_REVISION)
  end

  # Jenkins may return empty string as attribute value which we must ignore
  def attribute(value, default_value=nil)
    str = value.to_s
    not(str.empty?) ? str : default_value
  end

  # pseudo semaphore
  def synchronize(dir)
    begin
      lock_acquire(dir)
      yield
    ensure
      lock_release(dir)
    end
  end

  def lock_acquire(dir)
    begin
      run("mkdir #{dir.shellescape}")
    rescue RuntimeError
      sleep(8) # FIXME: should be configurable
      retry
    end
  end

  def lock_release(dir)
    begin
      run("rmdir #{dir.shellescape}")
    rescue RuntimeError
      run("rmdir #{dir.shellescape}")
    end
  end
end
