require 'spec_helper'
require 'backgrounder/workers/process_asset'

describe worker = CarrierWave::Workers::ProcessAsset do
  before do
    @user   = mock('User')
    @image  = mock('UserAsset')
    @worker = worker.new(@user, '22', :image)
  end

  context "#perform" do
    it 'processes versions' do
      @user.expects(:find).with('22').returns(@user).once
      @user.expects(:image).once.returns(@image)
      @user.expects(:process_image_upload=).with(true).once

      @image.expects(:recreate_versions!).once.returns(true)
      @user.expects(:respond_to?).with(:image_processing).once.returns(true)
      @user.expects(:update_attribute).with(:image_processing, nil).once

      @worker.perform
    end
  end
end
