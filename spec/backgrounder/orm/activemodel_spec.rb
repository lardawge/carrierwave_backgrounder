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
    it "calls up to processs column upload getter in the base class" do
      instance = @mock_class.new
      instance.expects(:process_avatar_upload)
      instance.trigger_avatar_background_processing?
    end
  end
end
