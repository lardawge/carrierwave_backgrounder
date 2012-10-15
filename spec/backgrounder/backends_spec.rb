require 'spec_helper'
require 'carrierwave_backgrounder'

describe CarrierWave::Backgrounder do

  describe 'enumerating available backends' do

    it 'detects GirlFriday' do
      CarrierWave::Backgrounder.available_backends.should include(:girl_friday)
    end
    it 'detects Delayed::Job' do
      CarrierWave::Backgrounder.available_backends.should include(:delayed_job)
    end
    it 'detects Resque' do
      CarrierWave::Backgrounder.available_backends.should include(:resque)
    end
    it 'detects Qu' do
      CarrierWave::Backgrounder.available_backends.should include(:qu)
    end
    it 'detects Sidekiq' do
      CarrierWave::Backgrounder.available_backends.should include(:sidekiq)
    end
    it 'detects QC' do
      CarrierWave::Backgrounder.available_backends.should include(:qc)
    end
  end

  describe 'automatically setting backends' do

    before do
      CarrierWave::Backgrounder.instance_variable_set('@backend', nil)
    end

    it 'does not set a backend if none are available' do
      suppress_warnings do
        CarrierWave::Backgrounder.stubs(:available_backends).returns([])
        CarrierWave::Backgrounder.backend.should be_nil
      end
    end
    it 'sets a backend automatically if only one is available' do
      CarrierWave::Backgrounder.stubs(:available_backends).returns([ :qu ])
      CarrierWave::Backgrounder.backend.should eq(:qu)
    end
    it 'does not set a backend if more than one is available' do
      suppress_warnings do
        CarrierWave::Backgrounder.stubs(:available_backends).returns([:qu, :resque])
        CarrierWave::Backgrounder.backend.should be_nil
      end
    end

    it 'does not clobber a manually set backend' do
      CarrierWave::Backgrounder.backend = :not_a_backend
      CarrierWave::Backgrounder.backend.should eq(:not_a_backend)
    end

    it 'calls configure_backend when setting the backend' do
      CarrierWave::Backgrounder.stubs(:available_backends).returns([ :qu ])
      CarrierWave::Backgrounder.expects(:configure_backend).once
      CarrierWave::Backgrounder.backend.should eq(:qu)
    end

  end



end

