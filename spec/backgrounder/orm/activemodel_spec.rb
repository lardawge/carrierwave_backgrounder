require 'spec_helper'
require 'ostruct'
require 'backgrounder/orm/activemodel'

RSpec.describe CarrierWave::Backgrounder::ORM::ActiveModel do
  before do
    @mock_class = Class.new do
      def self.before_save(method, opts); nil; end
      def self.after_commit(method, opts); nil; end
      def avatar_changed?; nil;  end
      def remote_avatar_url; OpenStruct.new(:present? => true); end
      def remove_avatar?; false; end
      def previous_changes; {}; end
      def self.uploader_options; {}; end
    end

    @mock_class.extend CarrierWave::Backgrounder::ORM::ActiveModel
  end

  describe '.store_in_background' do
    context 'setting up callbacks' do
      it 'creates an after_commit hook' do
        expect(@mock_class).to receive(:after_commit).with(:enqueue_avatar_background_job,  { if: :enqueue_avatar_background_job? })
        @mock_class.store_in_background :avatar
      end
    end
  end

  describe '.process_in_background' do
    context 'setting up callbacks' do
      it 'creates a before_save hook' do
        expect(@mock_class).to receive(:before_save).with(:set_avatar_processing, { if: :enqueue_avatar_background_job? })
        @mock_class.process_in_background :avatar
      end

      it 'creates an after_save hook' do
        expect(@mock_class).to receive(:after_commit).with(:enqueue_avatar_background_job, { if: :enqueue_avatar_background_job? })
        @mock_class.process_in_background :avatar
      end
    end
  end

  describe '#trigger_column_background_processing?' do
    let(:instance) { @mock_class.new }

    before do
      @mock_class.process_in_background :avatar
    end

    context 'mount_on option is set' do
      before do
        options_hash = {:avatar => {:mount_on => :some_other_column}}
        expect(@mock_class).to receive(:uploader_options).and_return(options_hash)
      end

      it "returns true if alternate column is changed" do
        expect(instance).to receive(:some_other_column_changed?).and_return(true)
        expect(instance.avatar_updated?).to be_truthy
      end
    end

    it "returns true if process_avatar_upload is false" do
      expect(instance).to receive(:process_avatar_upload)
      expect(instance.enqueue_avatar_background_job?).to be_truthy
    end

    it "calls column_changed?" do
      expect(instance).to receive(:process_avatar_upload).and_return(false)
      expect(instance).to receive(:avatar_changed?)
      expect(instance.enqueue_avatar_background_job?).to be_truthy
    end

    it "calls previous_changes" do
      expect(instance).to receive(:process_avatar_upload).and_return(false)
      expect(instance).to receive(:avatar_changed?).and_return(false)
      expect(instance).to receive(:previous_changes).and_return({:avatar => true})
      expect(instance.enqueue_avatar_background_job?).to be_truthy
    end

    it "calls avatar_remote_url" do
      expect(instance).to receive(:process_avatar_upload).and_return(false)
      expect(instance).to receive(:avatar_changed?).and_return(false)
      expect(instance).to receive(:previous_changes).and_return({})
      expect(instance).to receive(:remote_avatar_url).and_return('yup')
      expect(instance.enqueue_avatar_background_job?).to be_truthy
    end

    it "calls avatar_cache" do
      expect(instance).to receive(:process_avatar_upload).and_return(false)
      expect(instance).to receive(:avatar_changed?).and_return(false)
      expect(instance).to receive(:previous_changes).and_return({})
      expect(instance).to receive(:remote_avatar_url).and_return(nil)
      expect(instance).to receive(:avatar_cache).and_return('yup')
      expect(instance.enqueue_avatar_background_job?).to be_truthy
    end
  end
end
