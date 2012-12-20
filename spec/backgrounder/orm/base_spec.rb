require 'spec_helper'


describe CarrierWave::Backgrounder::ORM::Base do
  before do
    @mock_class = Class.new do
      def self.before_save(method, opts); nil; end
      def self.after_commit(method, opts); nil; end
    end

    @mock_class.extend CarrierWave::Backgrounder::ORM::Base
  end

  it 'mixes in the two DSL methods' do
    expect(@mock_class).to respond_to(:process_in_background)
    expect(@mock_class).to respond_to(:store_in_background)
  end

  describe '.process_in_background' do
    context 'including new methods' do
      before do
        @mock_class.process_in_background :avatar
        @instance = @mock_class.new
      end

      it 'creates a processing enabled accessor' do
        expect(@instance).to respond_to(:process_avatar_upload)
        expect(@instance).to respond_to(:process_avatar_upload=)
      end

      it 'create a setter for the processing attribute' do
        expect(@instance).to respond_to(:set_avatar_processing)
      end

      it 'create a background job queuer' do
        expect(@instance).to respond_to(:enqueue_avatar_background_job)
      end

      it 'create a trigger interrogator' do
        expect(@instance).to respond_to(:enqueue_avatar_background_job?)
      end
    end
  end

  describe 'store in background' do
    describe 'including new methods' do
      before do
        @mock_class.store_in_background :avatar
        @instance = @mock_class.new
      end

      it 'creates a processing enabled accessor' do
        expect(@instance).to respond_to(:process_avatar_upload)
        expect(@instance).to respond_to(:process_avatar_upload=)
      end

      it 'overrides the write column identifier method from carrierwave' do
        expect(@instance).to respond_to(:write_avatar_identifier)
      end

      it 'overrides the store column method from carrierwave' do
        expect(@instance).to respond_to(:store_avatar!)
      end

      it 'create a background job queuer' do
        expect(@instance).to respond_to(:enqueue_avatar_background_job)
      end

      it 'create a trigger interrogator' do
        expect(@instance).to respond_to(:enqueue_avatar_background_job?)
      end
    end
  end
end
