require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class HaltSuccessError < StandardError; end

describe Redfinger::Client do
  describe '#new' do
    it 'should add acct: if it is not in URI form' do
      Redfinger::Client.new('abc@example.com').account.should == 'acct:abc@example.com'
    end
    
    it 'should not add acct: if it is already in URI form' do
      Redfinger::Client.new('acct:abc@example.com').account.should == 'acct:abc@example.com'
    end
    
    it 'should set the domain to whatevers after the @ sign' do
      Redfinger::Client.new('abc@example.com').domain.should == 'example.com'
      Redfinger::Client.new('abc@frog.co.uk').domain.should == 'frog.co.uk'
    end
  end
  
  describe '#retrieve_template_from_xrd' do
    it 'should make an SSL request to get the host XRD document' do
      stub_request(:get, 'https://example.com/.well-known/host-meta').to_raise(HaltSuccessError)
      lambda{Redfinger::Client.new('acct:abc@example.com').send(:retrieve_template_from_xrd)}.should raise_error(HaltSuccessError)
    end
    
    it 'should make an HTTP request if HTTPS cannot connect' do
      stub_request(:get, 'https://example.com/.well-known/host-meta').to_raise(Errno::ECONNREFUSED)
      stub_request(:get, 'http://example.com/.well-known/host-meta').to_raise(HaltSuccessError)
      lambda{Redfinger::Client.new('acct:abc@example.com').send(:retrieve_template_from_xrd)}.should raise_error(HaltSuccessError)
    end
    
    it 'should raise Redfinger::ResourceNotFound if HTTP fails as well' do
      stub_request(:get, 'https://example.com/.well-known/host-meta').to_raise(Errno::ECONNREFUSED)
      stub_request(:get, 'http://example.com/.well-known/host-meta').to_raise(Errno::ECONNREFUSED)
      lambda{Redfinger::Client.new('acct:abc@example.com').send(:retrieve_template_from_xrd)}.should raise_error(Redfinger::ResourceNotFound)
    end
    
    it 'should raise Redfinger::ResourceNotFound on 404 as well as HTTP fail' do
      stub_request(:get, /.well-known\/host-meta/).to_return(:status => 404, :body => '404 Not Found')
      lambda{Redfinger::Client.new('acct:abc@example.com').send(:retrieve_template_from_xrd)}.should raise_error(Redfinger::ResourceNotFound)
    end
    
    it 'should return the template' do
      stub_request(:get, 'https://example.com/.well-known/host-meta').to_return(:status => 200, :body => host_xrd)
      Redfinger::Client.new('acct:abc@example.com').send(:retrieve_template_from_xrd).should == 'http://example.com/webfinger/?q={uri}'
    end
    
    it 'should raise a SecurityException if there is a host mismatch' do
      stub_request(:get, 'https://franklin.com/.well-known/host-meta').to_return(:status => 200, :body => host_xrd)
      lambda{Redfinger::Client.new('acct:abc@franklin.com').send(:retrieve_template_from_xrd)}.should raise_error(Redfinger::SecurityException)
    end
  end
  
  describe '#finger' do
    it 'should fetch the URI template if is not set' do
      stub_success
      @client = Redfinger::Client.new('abc@example.com')
      @client.should_receive(:retrieve_template_from_xrd).and_raise(HaltSuccessError)
      lambda{@client.finger}.should raise_error(HaltSuccessError)
    end
    
    it 'should NOT fetch the URI template if it is already set' do
      stub_success
      @client = Redfinger::Client.new('abc@example.com')
      @client.should_not_receive(:retrieve_template_from_xrd)
      @client.uri_template = 'http://example.com/webfinger/?q={uri}'
      @client.finger
    end
    
    it 'should return a Finger' do
      stub_success
      Redfinger::Client.new('abc@example.com').finger.should be_kind_of(Redfinger::Finger)
    end
  end
end