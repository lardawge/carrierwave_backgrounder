require 'spec_helper'

class BaseUploader
  def process!(*args)
    'processed'
  end

  def store_versions!(*args)
    'processed'
  end

  def cache_versions!(*args)
    'processed'
  end
end

class Uploader < BaseUploader
  include CarrierWave::Backgrounder::Delay

  def model
    self
  end
end

RSpec.describe CarrierWave::Backgrounder::Delay do
  describe 'process!' do
    context 'processing is disabled and backgrounding is enabled' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(false)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(true)

        expect(@uploader.process!).to eq nil
      end
    end

    context 'processing is disabled and backgrounding is disabled' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(false)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(false)

        expect(@uploader.process!).to eq nil
      end
    end

    context 'processing is enabled and backrounding is disabled' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(true)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(false)

        expect(@uploader.process!).to eq nil
      end
    end

    context 'processing is enabled and backrounding is enabled' do
      it 'process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(true)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(true)

        expect(@uploader.process!).to eq 'processed'
      end
    end

    context 'processing is disabled and background methods is not defined' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(false)
        allow(@uploader).to receive(:mounted_as).and_return('test')

        expect(@uploader.process!).to eq nil
      end
    end

    context 'processing is enabled and background methods is not defined' do
      it 'process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(true)
        allow(@uploader).to receive(:mounted_as).and_return('test')

        expect(@uploader.process!).to eq 'processed'
      end
    end
  end

  describe 'store_versions!' do
    context 'processing is disabled and backgrounding is enabled' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(false)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(true)

        expect(@uploader.store_versions!).to eq nil
      end
    end

    context 'processing is disabled and backgrounding is disabled' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(false)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(false)

        expect(@uploader.store_versions!).to eq nil
      end
    end

    context 'processing is enabled and backrounding is disabled' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(true)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(false)

        expect(@uploader.store_versions!).to eq nil
      end
    end

    context 'processing is enabled and backrounding is enabled' do
      it 'process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(true)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(true)

        expect(@uploader.store_versions!).to eq 'processed'
      end
    end

    context 'processing is disabled and background methods is not defined' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(false)
        allow(@uploader).to receive(:mounted_as).and_return('test')

        expect(@uploader.store_versions!).to eq nil
      end
    end

    context 'processing is enabled and background methods is not defined' do
      it 'process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(true)
        allow(@uploader).to receive(:mounted_as).and_return('test')

        expect(@uploader.store_versions!).to eq 'processed'
      end
    end
  end


  describe 'cache_versions!' do
    context 'processing is disabled and backgrounding is enabled' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(false)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(true)

        expect(@uploader.cache_versions!(nil)).to eq nil
      end
    end

    context 'processing is disabled and backgrounding is disabled' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(false)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(false)

        expect(@uploader.cache_versions!(nil)).to eq nil
      end
    end

    context 'processing is enabled and backrounding is disabled' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(true)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(false)

        expect(@uploader.cache_versions!(nil)).to eq nil
      end
    end

    context 'processing is enabled and backrounding is enabled' do
      it 'process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(true)
        allow(@uploader).to receive(:mounted_as).and_return('test')
        allow(@uploader).to receive(:process_test_upload).and_return(true)

        expect(@uploader.cache_versions!(nil)).to eq 'processed'
      end
    end

    context 'processing is disabled and background methods is not defined' do
      it 'do not process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(false)
        allow(@uploader).to receive(:mounted_as).and_return('test')

        expect(@uploader.cache_versions!(nil)).to eq nil
      end
    end

    context 'processing is enabled and background methods is not defined' do
      it 'process file' do
        @uploader = Uploader.new

        allow(@uploader).to receive(:enable_processing).and_return(true)
        allow(@uploader).to receive(:mounted_as).and_return('test')

        expect(@uploader.cache_versions!(nil)).to eq 'processed'
      end
    end
  end
end
