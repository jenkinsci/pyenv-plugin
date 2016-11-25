#!/usr/bin/env ruby

require "delegate"
require "pyenv/errors"
require "pyenv/invoke"
require "pyenv/scm"
require "pyenv/semaphore"

module Pyenv
  class Environment < SimpleDelegator
    include Pyenv::InvokeCommand
    include Pyenv::Semaphore

    def initialize(build_wrapper)
      @build_wrapper = build_wrapper
      super(build_wrapper)
    end

    def setup!
      install!
      detect_version!

      # To avoid starting multiple build jobs, acquire lock during installation
      synchronize("#{pyenv_root}.lock") do
        available_versions = capture(pyenv("versions", "--bare")).strip.split
        to_install = (version.split(":") - available_versions).uniq
        unless to_install.empty?
          update!
        end
        to_install.each do |version|
          listener << "Installing #{version}..."
          run(pyenv("install", version), {out: listener})
          listener << "Installed #{version}."
        end
        pip_install!
      end

      build.env["PYENV_ROOT"] = pyenv_root
      build.env['PYENV_VERSION'] = version
      # Set ${PYENV_ROOT}/bin in $PATH to allow invoke pyenv from shell
      build.env["PATH+PYENV_BIN"] = "#{pyenv_root}/bin"
      # Set ${PYENV_ROOT}/bin in $PATH to allow invoke binstubs from shell
      build.env["PATH+PYENV_SHIMS"] = "#{pyenv_root}/shims"
    end

    private
    def install!
      unless test("[ -d #{pyenv_root.shellescape} ]")
        listener << "Installing pyenv..."
        run(Pyenv::SCM::Git.new(pyenv_repository, pyenv_revision, pyenv_root).checkout, {out: listener})
        listener << "Installed pyenv."
      end
    end

    def detect_version!
      if ignore_local_version
        listener << "Just ignoring local Python version."
      else
        # Respect local Python version if defined in the workspace
        get_local_version(build.workspace.to_s).tap do |version|
          if version
            listener << "Use local Python version #{version}."
            self.version = version # call PyenvWrapper's accessor
          end
        end
      end
    end

    def get_local_version(path)
      str = capture("cd #{path.shellescape} && #{pyenv("local")} 2>/dev/null || true").strip
      str = str.split.join(":")  # to support multiple versions setting via environment variable
      not(str.empty?) ? str : nil
    end

    def update!
      # To update definitions, update pyenv before installing python
      listener << "Updating pyenv..."
      run(Pyenv::SCM::Git.new(pyenv_repository, pyenv_revision, pyenv_root).sync, {out: listener})
      listener << "Updated pyenv."
    end

    def pip_install!
      # Run rehash everytime before invoking pip
      run(pyenv("rehash"), {out: listener})

      list = capture(pyenv("exec", "pip", "list")).strip.split
      pip_list.split(",").each do |pip|
        unless list.include?(pip)
          listener << "Installing #{pip}..."
          run(pyenv("exec", "pip", "install", pip), {out: listener})
          listener << "Installed #{pip}."
        end
      end

      # Run rehash everytime after invoking pip
      run(pyenv("rehash"), {out: listener})
    end

    def pyenv(*args)
      (["env", "PYENV_ROOT=#{pyenv_root}", "PYENV_VERSION=#{version}", "#{pyenv_root}/bin/pyenv"] + args).shelljoin
    end
  end
end
