#!/usr/bin/env ruby

module Pyenv
  class PyenvError < StandardError
  end

  class CommandError < PyenvError
  end

  class LockError < PyenvError
  end
end
