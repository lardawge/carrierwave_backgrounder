require 'spec_helper'
require 'backgrounder/workers/store_asset'

describe worker = CarrierWave::Workers::StoreAsset do
  before do
    @user   = mock('User')
    @image  = mock('UserAsset')
    @worker = worker.new(@user, '22', :image)
  end

  context "#perform" do
    it 'processes versions' do
      File.expects(:open).with('../fixtures/test.jpg').once.returns('apple')
      FileUtils.expects(:rm).with('../fixtures/test.jpg').once
      @user.expects(:find).with('22').once.returns(@user)
      @user.expects(:image_tmp).once.returns('test.jpg')
      @user.expects(:image).once.returns(@image)
      @image.expects(:root).once.returns('..')
      @image.expects(:cache_dir).once.returns('fixtures')
      @user.expects(:process_image_upload=).with(true).once
      @user.expects(:image=).with('apple').once
      @user.expects(:image_tmp=).with(nil).once
      @user.expects(:save!).once.returns(true)

      @worker.perform
    end
  end
end
