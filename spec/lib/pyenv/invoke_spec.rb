require "spec_helper"
require "pyenv/invoke"
require "shellwords"
require "stringio"

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

  it "should raise error on run failed" do
    launcher.should_receive(:execute).with("bash", "-c", "false", {}).and_return(1)
    lambda { pyenv.run("false") }.should raise_error(Pyenv::CommandError)
  end

  it "should return command output as string" do
    out = StringIO.new("hello, world")
    launcher.should_receive(:execute).with("bash", "-c", "echo hello,\\ world", {out: out}).and_return(0)
    pyenv.capture(["echo", "hello, world"].shelljoin, {out: out}).should == "hello, world"
  end

  it "should raise error on capture failed" do
    out = StringIO.new("")
    launcher.should_receive(:execute).with("bash", "-c", "exit 1", {out: out}).and_return(1)
    lambda { pyenv.capture(["exit", "1"].shelljoin, {out: out}) }.should raise_error(Pyenv::CommandError)
  end
end
