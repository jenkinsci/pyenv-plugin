require "spec_helper"
require "pyenv/semaphore"

describe Pyenv::Semaphore do
  let(:pyenv) do
    stub.extend(Pyenv::Semaphore)
  end

  let(:release_options) do
    {
      :acquire_max => 1,
      :acquire_wait => 1,
      :release_max => 1,
      :release_wait => 1,
    }
  end

  it "should acquire lock" do
    pyenv.should_receive(:test).with("mkdir true").and_return(true)
    pyenv.acquire_lock("true")
  end

  it "should not acquire lock" do
    pyenv.should_receive(:test).with("mkdir false").and_return(false)
    lambda { pyenv.acquire_lock("false", release_options) }.should raise_error(Pyenv::LockError)
  end

  it "should release lock" do
    pyenv.should_receive(:test).with("rmdir true").and_return(true)
    pyenv.release_lock("true")
  end

  it "should not release lock" do
    pyenv.should_receive(:test).with("rmdir false").and_return(false)
    lambda { pyenv.release_lock("false", release_options) }.should raise_error(Pyenv::LockError)
  end
end
