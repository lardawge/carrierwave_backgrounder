# encoding: utf-8
require 'spec_helper'
require 'backgrounder/workers/store_asset'

RSpec.describe CarrierWave::Workers::StoreAsset do
  let(:fixtures_path) { File.expand_path('../fixtures/images', __FILE__) }
  let(:worker_class) { CarrierWave::Workers::StoreAsset }
  let(:user) { double('User') }
  let!(:worker) { worker_class.new(user, '22', :image) }

  describe ".perform" do
    it 'creates a new instance and calls perform' do
      args = [user, '22', :image]
      expect(worker_class).to receive(:new).with(*args).and_return(worker)
      expect_any_instance_of(worker_class).to receive(:perform)
      worker_class.perform(*args)
    end
  end

  describe "#perform" do
    let(:image)  { double('UserAsset') }

    before do
      allow(image).to receive(:root).once.and_return(File.expand_path('..', __FILE__))
      allow(image).to receive(:cache_dir).once.and_return('fixtures')
      allow(user).to receive(:image_tmp).twice.and_return('images/test.jpg')
      allow(user).to receive(:find).with('22').once.and_return(user)
      allow(user).to receive(:image).once.and_return(image)
      allow(user).to receive(:process_image_upload=).with(true).once
      allow(user).to receive(:image=).once
      allow(user).to receive(:image_tmp=).with(nil).once
    end

    it 'removes tmp directory on success' do
      expect(FileUtils).to receive(:rm_r).with(fixtures_path, force: true).once
      expect(user).to receive(:save!).once.and_return(true)
      worker.perform
    end

    it 'does not remove the tmp directory if save! fails' do
      expect(FileUtils).to receive(:rm_r).never
      expect(user).to receive(:save!).once.and_return(false)
      worker.perform
    end

    it 'sets the cache_path' do
      expect(user).to receive(:save!).once.and_return(false)
      worker.perform
      expect(worker.cache_path).to eql(fixtures_path + '/test.jpg')
    end

    it 'sets the tmp_directory' do
      expect(user).to receive(:save!).once.and_return(false)
      worker.perform
      expect(worker.tmp_directory).to eql(fixtures_path)
    end
  end

  describe '#perform with args' do
    let(:admin) { double('Admin') }
    let(:image)  { double('AdminAsset') }
    let(:worker) { worker_class.new }

    before do
      allow(image).to receive(:root).once.and_return(File.expand_path('..', __FILE__))
      allow(image).to receive(:cache_dir).once.and_return('fixtures')
      allow(admin).to receive(:avatar_tmp).twice.and_return('images/test.jpg')
      allow(admin).to receive(:find).with('23').once.and_return(admin)
      allow(admin).to receive(:avatar).once.and_return(image)
      allow(admin).to receive(:process_avatar_upload=).with(true).once
      allow(admin).to receive(:avatar=).once
      allow(admin).to receive(:avatar_tmp=).with(nil).once
      allow(admin).to receive(:save!).once.and_return(false)
      worker.perform admin, '23', :avatar
    end

    it 'sets klass' do
      expect(worker.klass).to eql(admin)
    end

    it 'sets column' do
      expect(worker.id).to eql('23')
    end

    it 'sets id' do
      expect(worker.column).to eql(:avatar)
    end
  end

  describe '#store_directories' do
    let(:record) { double('Record') }

    context 'cache_path' do
      it 'sets the cache_path correctly if a full path is set for the cache_dir' do
        root = '/Users/lar/Sites/bunker/public'
        cache_dir = '/Users/lar/Sites/bunker/tmp/uploads'
        asset = double(:cache_dir => cache_dir, :root => root)
        expect(record).to receive(:image).and_return(asset)
        expect(record).to receive(:image_tmp).and_return('images/test.jpg')
        worker.send :store_directories, record
        expect(worker.cache_path).to eql('/Users/lar/Sites/bunker/tmp/uploads/images/test.jpg')
      end

      it 'sets the cache_path correctly if a partial path is set for cache_dir' do
        root = '/Users/lar/Sites/bunker/public'
        cache_dir = 'uploads/tmp'
        asset = double(:cache_dir => cache_dir, :root => root)
        expect(record).to receive(:image).and_return(asset)
        expect(record).to receive(:image_tmp).and_return('images/test.jpg')
        worker.send :store_directories, record
        expect(worker.cache_path).to eql('/Users/lar/Sites/bunker/public/uploads/tmp/images/test.jpg')
      end
    end

    context 'tmp_directory' do
      it 'sets the tmp_directory correctly if a full path is set for the cache_dir' do
        root = '/Users/lar/Sites/bunker/public'
        cache_dir = '/Users/lar/Sites/bunker/tmp/uploads'
        asset = double(:cache_dir => cache_dir, :root => root)
        expect(record).to receive(:image).and_return(asset)
        expect(record).to receive(:image_tmp).and_return('images/test.jpg')
        worker.send :store_directories, record
        expect(worker.tmp_directory).to eql('/Users/lar/Sites/bunker/tmp/uploads/images')
      end

      it 'sets the tmp_directory correctly if a partial path is set for cache_dir' do
        root = '/Users/lar/Sites/bunker/public'
        cache_dir = 'uploads/tmp'
        asset = double(:cache_dir => cache_dir, :root => root)
        expect(record).to receive(:image).and_return(asset)
        expect(record).to receive(:image_tmp).and_return('images/test.jpg')
        worker.send :store_directories, record
        expect(worker.tmp_directory).to eql('/Users/lar/Sites/bunker/public/uploads/tmp/images')
      end
    end
  end
end
