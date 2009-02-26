require File.dirname(__FILE__) + '/spec_helper'

describe Stapler::Mount do
  
  include SanitizedFileSpecHelper
  
  after do
    FileUtils.rm_rf(public_path)
  end

  describe '.mount_uploader' do
    
    before do
      @class = Class.new
      @class.send(:extend, Stapler::Mount)
      
      @uploader = Class.new(Stapler::Uploader)

      @class.mount_uploader(:image, @uploader)
      @instance = @class.new
    end
    
    describe '#image' do
      
      it "should return nil when nothing has been assigned" do
        @instance.should_receive(:read_uploader).with(:image).and_return(nil)
        @instance.image.should be_nil
      end
      
      it "should return nil when an empty string has been assigned" do
        @instance.should_receive(:read_uploader).with(:image).and_return('')
        @instance.image.should be_nil
      end
      
      it "should retrieve a file from the storage if a value is stored in the database" do
        @instance.should_receive(:read_uploader).with(:image).and_return('test.jpg')
        @instance.image.should be_an_instance_of(@uploader)
      end
      
      it "should set the path to the store dir" do
        @instance.should_receive(:read_uploader).with(:image).and_return('test.jpg')
        @instance.image.current_path.should == public_path('uploads/test.jpg')
      end
    
    end
    
    describe '#image=' do
      
      it "should cache a file" do
        @instance.image = stub_file('test.jpg')
        @instance.image.should be_an_instance_of(@uploader)
      end
      
      it "should copy a file into into the cache directory" do
        @instance.image = stub_file('test.jpg')
        @instance.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
      end
      
      it "should do nothing when nil is assigned" do
        @instance.should_not_receive(:write_uploader)
        @instance.image = nil
      end
      
      it "should do nothing when an empty string is assigned" do
        @instance.should_not_receive(:write_uploader)
        @instance.image = ''
      end
      
    end

    describe '#image_cache' do

      before do
        @instance.stub!(:write_uploader)
        @instance.stub!(:read_uploader).and_return(nil)
      end

      it "should return nil when nothing has been assigned" do
        @instance.image_cache.should be_nil
      end

      it "should be nil when a file has been stored" do
        @instance.image = stub_file('test.jpg')
        @instance.image.store!
        @instance.image_cache.should be_nil
      end

      it "should be the cache name when a file has been cached" do
        @instance.image = stub_file('test.jpg')
        @instance.image_cache.should =~ %r(^[\d]{8}\-[\d]{4}\-[\d]+\-[\d]{4}/test\.jpg$)
      end

    end
    
    describe '#image_cache=' do

      before do
        @instance.stub!(:write_uploader)
        @instance.stub!(:read_uploader).and_return(nil)
      end

      it "should do nothing when nil is assigned" do
        @instance.image_cache = nil
        @instance.image.should be_nil
      end

      it "should do nothing when an empty string is assigned" do
        @instance.image_cache = ''
        @instance.image.should be_nil
      end

      it "retrieve from cache when a cache name is assigned" do
        @instance.image_cache = '19990512-1202-123-1234/test.jpg'
        @instance.image.current_path.should == public_path('uploads/tmp/19990512-1202-123-1234/test.jpg')
      end

      it "should not write over a previously assigned file" do
        @instance.image = stub_file('test.jpg')
        @instance.image_cache = '19990512-1202-123-1234/monkey.jpg'
        @instance.image.current_path.should =~ /test.jpg$/
      end
    end

    describe '#store_image!' do

      before do
        @instance.stub!(:write_uploader)
        @instance.stub!(:read_uploader).and_return(nil)
      end

      it "should do nothing when no file has been uploaded" do
        @instance.store_image!
        @instance.image.should be_nil
      end

      it "store an assigned file" do
        @instance.image = stub_file('test.jpg')
        @instance.store_image!
        @instance.image.current_path.should == public_path('uploads/test.jpg')
      end
    end

  end
  
  describe '#mount_uploader with a block' do
   
    before do
      @class = Class.new
      @class.send(:extend, Stapler::Mount)
      @class.mount_uploader(:image) do
        def monkey
          'blah'
        end
      end
      @instance = @class.new
    end
    
    describe '#image' do
      
      before do
        @instance.stub!(:read_uploader).and_return('test.jpg')
      end
      
      it "should return an instance of a subclass of Stapler::Uploader" do
        @instance.image.should be_a(Stapler::Uploader)
      end
      
      it "should set the path to the store dir" do
        @instance.image.current_path.should == public_path('uploads/test.jpg')
      end
    
      it "should apply any custom modifications" do
        @instance.image.monkey.should == "blah"
      end
    
    end
    
  end
  
end