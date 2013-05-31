require "spec_helper"
require "pyenv/invoke"

describe Pyenv::InvokeCommand do
  let(:launcher) do
    stub
  end

  let(:pyenv) do
    stub(:launcher => launcher).extend(Pyenv::InvokeCommand)
  end

  it "should return true on test success" do
    launcher.should_receive(:execute).with("bash", "-c", "true", {}).and_return(0)
    pyenv.test("true").should == true
  end

  it "should return false on test failure" do
    launcher.should_receive(:execute).with("bash", "-c", "false", {}).and_return(1)
    pyenv.test("false").should == false
  end

  it "should success on run success" do
    launcher.should_receive(:execute).with("bash", "-c", "true", {}).and_return(0)
    pyenv.run("true")
  end

  it "should raise an error on run failed" do
    launcher.should_receive(:execute).with("bash", "-c", "false", {}).and_return(1)
    lambda { pyenv.run("false") }.should raise_error(Pyenv::CommandError)
  end
end
