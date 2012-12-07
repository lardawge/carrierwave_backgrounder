require 'spec_helper'
require 'backgrounder/support/backends'

describe Support::Backends do
  let(:test_module) { Module.new }

  before do
    test_module.send :include, Support::Backends
  end

  describe 'enumerating available backends' do
    it 'detects GirlFriday' do
      test_module.available_backends.should include(:girl_friday)
    end

    it 'detects Delayed::Job' do
      test_module.available_backends.should include(:delayed_job)
    end
    
    it 'detects Resque' do
      test_module.available_backends.should include(:resque)
    end
    
    it 'detects Qu' do
      test_module.available_backends.should include(:qu)
    end
    
    it 'detects Sidekiq' do
      test_module.available_backends.should include(:sidekiq)
    end
    
    it 'detects QC' do
      test_module.available_backends.should include(:qc)
    end

    it 'detects Immediate' do
      test_module.available_backends.should include(:immediate)
    end
  end

  describe 'automatically setting backends' do
    before do
      test_module.instance_variable_set('@backend', nil)
    end

    it 'sets the backend to immediate if none available' do
      suppress_warnings do
        test_module.stubs(:available_backends).returns([])
        expect(test_module.backend).to eql(:immediate)
      end
    end

    it 'sets a backend automatically if only one is available' do
      test_module.stubs(:available_backends).returns([ :qu ])
      test_module.backend.should eq(:qu)
    end
    
    it 'does not set a backend if more than one is available' do
      suppress_warnings do
        test_module.stubs(:available_backends).returns([:qu, :resque])
        test_module.backend.should be_nil
      end
    end

    it 'does not clobber a manually set backend' do
      test_module.backend = :not_a_backend
      test_module.backend.should eq(:not_a_backend)
    end

    it 'calls configure_backend when setting the backend' do
      test_module.stubs(:available_backends).returns([ :qu ])
      test_module.expects(:configure_backend).once
      test_module.backend.should eq(:qu)
    end
  end
end

