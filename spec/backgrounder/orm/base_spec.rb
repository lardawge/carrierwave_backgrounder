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
    @mock_class.should respond_to(:process_in_background)
    @mock_class.should respond_to(:store_in_background)
  end

  describe 'process in background' do

    describe 'setting up callbacks' do

      it 'creates a before_save hook' do
        @mock_class.expects(:before_save).with(:set_avatar_processing, :if => :trigger_avatar_background_processing?)
        @mock_class.process_in_background :avatar
      end

      it 'creates an after_save hook' do
        @mock_class.expects(:after_commit).with(:enqueue_avatar_background_job, :if => :trigger_avatar_background_processing?)
        @mock_class.process_in_background :avatar
      end

    end

    describe 'including new methods' do
      before do
        @mock_class.process_in_background :avatar
        @instance = @mock_class.new
      end

      it 'creates a processing enabled accessor' do
        @instance.should respond_to(:process_avatar_upload)
        @instance.should respond_to(:process_avatar_upload=)
      end

      it 'create a setter for the processing attribute' do
        @instance.should respond_to(:set_avatar_processing)
      end

      it 'create a background job queuer' do
        @instance.should respond_to(:enqueue_avatar_background_job)
      end

      it 'create a trigger interrogator' do
        @instance.should respond_to(:trigger_avatar_background_processing?)
      end

    end

  end

  describe 'store in background' do

    describe 'setting up callbacks' do

      it 'creates an after_save hook' do
        @mock_class.expects(:after_commit).with(:enqueue_avatar_background_job, :if => :trigger_avatar_background_storage?)
        @mock_class.store_in_background :avatar
      end

    end

    describe 'including new methods' do
      before do
        @mock_class.store_in_background :avatar
        @instance = @mock_class.new
      end

      it 'creates a processing enabled accessor' do
        @instance.should respond_to(:process_avatar_upload)
        @instance.should respond_to(:process_avatar_upload=)
      end

      it 'overrides the write column identifier method from carrierwave' do
        @instance.should respond_to(:write_avatar_identifier)
      end

      it 'overrides the store column method from carrierwave' do
        @instance.should respond_to(:store_avatar!)
      end

      it 'create a background job queuer' do
        @instance.should respond_to(:enqueue_avatar_background_job)
      end

      it 'create a trigger interrogator' do
        @instance.should respond_to(:trigger_avatar_background_storage?)
      end

    end
  end

end
