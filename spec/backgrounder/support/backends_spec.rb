require 'spec_helper'
require 'support/backend_constants'
require 'support/mock_worker'

describe Support::Backends do
  let(:mock_module) { Module.new }

  before do
    mock_module.send :include, Support::Backends
  end

  describe 'enumerating available backends' do
    it 'detects GirlFriday' do
      expect(mock_module.available_backends).to include(:girl_friday)
    end

    it 'detects Delayed::Job' do
      expect(mock_module.available_backends).to include(:delayed_job)
    end
    
    it 'detects Resque' do
      expect(mock_module.available_backends).to include(:resque)
    end
    
    it 'detects Qu' do
      expect(mock_module.available_backends).to include(:qu)
    end
    
    it 'detects Sidekiq' do
      expect(mock_module.available_backends).to include(:sidekiq)
    end
    
    it 'detects QC' do
      expect(mock_module.available_backends).to include(:qc)
    end
  end

  describe 'setting backend' do
    it 'using #backend=' do
      mock_module.backend = :delayed_job
      expect(mock_module.backend).to eql(:delayed_job)
    end

    it 'using #backend' do
      mock_module.backend(:delayed_job)
      expect(mock_module.backend).to eql(:delayed_job)
    end

    it 'allows passing of queue_options' do
      mock_module.backend(:delayed_job, :queue => :awesome_queue)
      expect(mock_module.queue_options).to eql({:queue => :awesome_queue})
    end
  end

  describe 'auto detect backends' do
    before do
      mock_module.instance_variable_set('@backend', nil)
    end

    it 'sets the backend to immediate if none available' do
      suppress_warnings do
        mock_module.stubs(:available_backends).returns([])
        expect(mock_module.backend).to eql(:immediate)
      end
    end

    it 'sets a backend automatically if only one is available' do
      mock_module.stubs(:available_backends).returns([ :qu ])
      expect(mock_module.backend).to eql(:qu)
    end
    
    it 'raises an error if more than one backend is available' do
      mock_module.stubs(:available_backends).returns([:qu, :resque])
      expect {
       mock_module.backend
      }.to raise_error(CarrierWave::Backgrounder::TooManyBackendsAvailableError)
    end

    it 'does not clobber a manually set backend' do
      mock_module.backend = :not_a_backend
      expect(mock_module.backend).to eql(:not_a_backend)
    end
  end

  describe '#enqueue_for_backend' do
    let!(:worker) { MockWorker.new('FakeClass', 1, :image) }

    context 'delayed_job' do
      before do
        @mock_worker = Class.new do
          def self.perform(*args); new(*args).perform; end
        end

        MockWorker.expects(:new).returns(worker)
      end

      it 'defaults the queue name to nil if none passed to #backend' do
        mock_module.backend :delayed_job
        Delayed::Job.expects(:enqueue).with(worker, :queue => nil)
        mock_module.enqueue_for_backend MockWorker, 'FakeClass', 1, :image
      end

      it 'sets the queue name to the queue name passed to #backend' do
        mock_module.backend :delayed_job, :queue => :awesome_queue
        Delayed::Job.expects(:enqueue).with(worker, :queue => :awesome_queue)
        mock_module.enqueue_for_backend MockWorker, 'FakeClass', 1, :image
      end
    end

    context 'resque' do
      let(:args) { [MockWorker, 'FakeClass', 1, :image] }

      before do
        Resque.expects(:enqueue).with(*args)
      end

      it 'sets a variable with the queue name, defaults to :carrierwave' do
        mock_module.backend :resque
        mock_module.enqueue_for_backend(*args)
        expect(MockWorker.instance_variable_get '@queue').to eql(:carrierwave)
      end

      it 'sets a variable to the queue name passed to #backend' do
        mock_module.backend :resque, :queue => :awesome_queue
        mock_module.enqueue_for_backend(*args)
        expect(MockWorker.instance_variable_get '@queue').to eql(:awesome_queue)
      end
    end

    context 'sidekiq' do
      let(:args) { [MockWorker, 'FakeClass', 1, :image] }
      before do
        Sidekiq::Client.expects(:enqueue).with(*args)
      end

      it 'sets sidekiq_options to empty hash and calls enqueue with passed args' do
        MockWorker.expects(:sidekiq_options).with({})
        mock_module.backend :sidekiq
        mock_module.enqueue_for_backend(*args)
      end

      it 'sets sidekiq_options to the options passed to backend' do
        options = {:retry => false, :timeout => 60, :queue => :awesome_queue}
        MockWorker.expects(:sidekiq_options).with(options)
        mock_module.backend :sidekiq, options
        mock_module.enqueue_for_backend(*args)
      end
    end

    context 'girl_friday' do
      let(:args) { [MockWorker, 'FakeClass', 1, :image] }

      it 'instantiates a GirlFriday work queue if one does not exist' do
        mock_module.backend :girl_friday
        GirlFriday::WorkQueue.expects(:new).with(:carrierwave, {}).returns([])
        mock_module.enqueue_for_backend(*args)
      end

      it 'instantiates a GirlFriday work queue passing the args to the queue' do
        mock_module.backend :girl_friday, :queue => :awesome_queue, :size => 3
        GirlFriday::WorkQueue.expects(:new).with(:awesome_queue, {:size => 3}).returns([])
        mock_module.enqueue_for_backend(*args)
      end

      it 'does not instantiate a GirlFriday work queue if one exists' do
        mock_module.backend :girl_friday
        mock_module.instance_variable_set('@girl_friday_queue', [])
        GirlFriday::WorkQueue.expects(:new).never
        mock_module.enqueue_for_backend(*args)
      end

      it 'add a worker to the girl_friday queue' do
        expected = [{ :worker => MockWorker.new('FakeClass', 1, :image) }]
        mock_module.backend :girl_friday
        mock_module.instance_variable_set('@girl_friday_queue', [])
        mock_module.enqueue_for_backend(*args)
        expect(mock_module.instance_variable_get '@girl_friday_queue').to eql(expected)
      end
    end

    context 'qu' do
      let(:args) { [MockWorker, 'FakeClass', 1, :image] }
      before do
        Qu.expects(:enqueue).with(*args)
      end

      it 'sets a variable with the queue name, defaults to :carrierwave' do
        mock_module.backend :qu
        mock_module.enqueue_for_backend(*args)
        expect(MockWorker.instance_variable_get '@queue').to eql(:carrierwave)
      end

      it 'sets a variable to the queue name passed to #backend' do
        mock_module.backend :qu, :queue => :awesome_queue
        mock_module.enqueue_for_backend(*args)
        expect(MockWorker.instance_variable_get '@queue').to eql(:awesome_queue)
      end
    end

    context 'qc' do
      it 'calls enqueue with the passed args' do
        QC.expects(:enqueue).with("MockWorker.perform", 'FakeClass', 1, 'image')
        mock_module.backend :qc
        mock_module.enqueue_for_backend(MockWorker, 'FakeClass', 1, :image)
      end
    end

    context 'immediate' do
      it 'instantiates a worker passing the args and calls perform' do
        worker = mock('Worker')
        MockWorker.expects(:new).with('FakeClass', 1, :image).returns(worker)
        worker.expects(:perform)
        mock_module.backend :immediate
        mock_module.enqueue_for_backend(MockWorker, 'FakeClass', 1, :image)
      end
    end

  end
end

