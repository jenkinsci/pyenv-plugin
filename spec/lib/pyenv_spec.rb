require "spec_helper"
require "pyenv"

describe Pyenv::Environment do
  let(:build_wrapper) do
    stub
  end

  let(:pyenv) do
    Pyenv::Environment.new(build_wrapper)
  end

  it 'should respond to #setup!' do
    pyenv.respond_to?(:setup!).should == true
  end
end
