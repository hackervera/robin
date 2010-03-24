require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Redfinger do
  describe '#finger' do
    it 'should initialize a new client' do
      Redfinger::Client.should_receive(:new).with('abc@example.com').and_return(mock("Redfinger::Client", :finger => nil))
      Redfinger.finger('abc@example.com')
    end
  end
end
