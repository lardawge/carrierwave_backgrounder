# encoding: utf-8
require 'spec_helper'
require 'backgrounder/workers/store_asset'

describe CarrierWave::Workers::StoreAsset do
  let(:worker_class) { CarrierWave::Workers::StoreAsset }
  let(:user)   { mock('User') }
  let(:image)  { mock('UserAsset') }
  let!(:worker) { worker_class.new(user, '22', :image) }

  context ".perform" do
    it 'creates a new instance and calls perform' do
      args = [user, '22', :image]
      worker_class.expects(:new).with(*args).returns(worker)
      worker_class.any_instance.expects(:perform)

      worker_class.perform(*args)
    end
  end

  context "#perform" do
    it 'processes versions' do
      FileUtils.expects(:rm).with(File.expand_path('../fixtures/test.jpg', __FILE__)).once
      user.expects(:find).with('22').once.returns(user)
      user.expects(:image_tmp).once.returns('test.jpg')
      user.expects(:image).once.returns(image)
      image.expects(:root).once.returns(File.expand_path '..', __FILE__)
      image.expects(:cache_dir).once.returns('fixtures')
      user.expects(:process_image_upload=).with(true).once
      user.expects(:image=).once
      user.expects(:image_tmp=).with(nil).once
      user.expects(:save!).once.returns(true)

      worker.perform
    end
  end
end
