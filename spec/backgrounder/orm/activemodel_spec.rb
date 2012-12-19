require 'spec_helper'
require 'ostruct'
require 'backgrounder/orm/activemodel'

describe CarrierWave::Backgrounder::ORM::ActiveModel do
  before do
    @mock_class = Class.new do
      def self.before_save(method, opts); nil; end
      def self.after_commit(method, opts); nil; end
      def avatar_changed?; nil;  end
      def remote_avatar_url; OpenStruct.new(:present? => true); end
      def previous_changes; {}; end
    end

    @mock_class.extend CarrierWave::Backgrounder::ORM::ActiveModel
    @mock_class.process_in_background :avatar
  end

  describe '#trigger_column_background_processing?' do
    let(:instance) { @mock_class.new }

    it "returns true if process_avatar_upload is false" do
      instance.expects(:process_avatar_upload)
      expect(instance.enqueue_avatar_background_job?).to be_true
    end

    it "calls column_changed?" do
      instance.expects(:process_avatar_upload).returns(false)
      instance.expects(:avatar_changed?)
      expect(instance.enqueue_avatar_background_job?).to be_true
    end

    it "calls previous_changes" do
      instance.expects(:process_avatar_upload).returns(false)
      instance.expects(:avatar_changed?).returns(false)
      instance.expects(:previous_changes).returns({:avatar => true})
      expect(instance.enqueue_avatar_background_job?).to be_true
    end

    it "calls avatar_remote_url" do
      instance.expects(:process_avatar_upload).returns(false)
      instance.expects(:avatar_changed?).returns(false)
      instance.expects(:previous_changes).returns({})
      instance.expects(:remote_avatar_url).returns('yup')
      expect(instance.enqueue_avatar_background_job?).to be_true
    end

    it "calls avatar_cache" do
      instance.expects(:process_avatar_upload).returns(false)
      instance.expects(:avatar_changed?).returns(false)
      instance.expects(:previous_changes).returns({})
      instance.expects(:remote_avatar_url).returns(nil)
      instance.expects(:avatar_cache).returns('yup')
      expect(instance.enqueue_avatar_background_job?).to be_true
    end
  end
end
