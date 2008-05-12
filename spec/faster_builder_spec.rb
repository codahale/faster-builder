require File.join(File.dirname(__FILE__), "spec_helper")

require "faster_builder"

describe FasterBuilder do
  it "should be a module" do
    FasterBuilder.should be_an_instance_of(Module)
  end
end