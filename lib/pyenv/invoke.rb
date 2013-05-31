#!/usr/bin/env ruby

require "pyenv/errors"

module Pyenv
  module InvokeCommand
    def capture(command, options={})
      out = StringIO.new
      run(command, options.merge({out: out}))
      out.rewind
      out.read
    end

    def run(command, options={})
      unless test(command, options)
        raise(CommandError.new("failed: #{command.inspect}"))
      end
    end

    def test(command, options={})
      invoke(command, options) == 0
    end

    def invoke(command, options={})
      launcher.execute("bash", "-c", command, options)
    end
  end
end
