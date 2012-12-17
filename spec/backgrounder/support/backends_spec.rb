require 'spec_helper'

class TestWorker < Struct.new(:klass, :id, :column)
  def self.perform(*args)
    new(*args).perform
  end

  def perform(*args)
    set_args(*args) unless args.empty?
  end

  def set_args(klass, id, column)
    self.klass, self.id, self.column = klass, id, column
  end
end

describe Support::Backends do
  let(:test_module) { Module.new }

  before do
    test_module.send :include, Support::Backends
  end

  describe 'enumerating available backends' do
    it 'detects GirlFriday' do
      expect(test_module.available_backends).to include(:girl_friday)
    end

    it 'detects Delayed::Job' do
      expect(test_module.available_backends).to include(:delayed_job)
    end
    
    it 'detects Resque' do
      expect(test_module.available_backends).to include(:resque)
    end
    
    it 'detects Qu' do
      expect(test_module.available_backends).to include(:qu)
    end
    
    it 'detects Sidekiq' do
      expect(test_module.available_backends).to include(:sidekiq)
    end
    
    it 'detects QC' do
      expect(test_module.available_backends).to include(:qc)
    end

    it 'detects Immediate' do
      expect(test_module.available_backends).to include(:immediate)
    end
  end

  describe 'setting backend' do
    it 'using #backend=' do
      test_module.backend = :delayed_job
      expect(test_module.backend).to eql(:delayed_job)
    end

    it 'using #backend' do
      test_module.backend(:delayed_job)
      expect(test_module.backend).to eql(:delayed_job)
    end

    it 'allows passing of queue_options' do
      test_module.backend(:delayed_job, queue: :awesome_queue)
      expect(test_module.queue_options).to eql({queue: :awesome_queue})
    end
  end

  describe 'auto detect backends' do
    before do
      test_module.instance_variable_set('@backend', nil)
    end

    it 'sets the backend to immediate if none available' do
      suppress_warnings do
        test_module.stubs(:available_backends).returns([])
        expect(test_module.backend).to eql(:immediate)
      end
    end

    it 'sets a backend automatically if only one is available' do
      test_module.stubs(:available_backends).returns([ :qu ])
      expect(test_module.backend).to eql(:qu)
    end
    
    it 'raises an error if more than one backend is available' do
      test_module.stubs(:available_backends).returns([:qu, :resque])
      expect {
       test_module.backend
      }.to raise_error(CarrierWave::Backgrounder::ToManyBackendsAvailableError)
    end

    it 'does not clobber a manually set backend' do
      test_module.backend = :not_a_backend
      expect(test_module.backend).to eql(:not_a_backend)
    end
  end

  describe '#enqueue_for_backend' do
    let!(:worker) { TestWorker.new('FakeClass', 1, :image) }

    context 'delayed_job' do
      before do
        TestWorker.expects(:new).returns(worker)
      end

      it 'defaults the queue name to nil if none passed to #backend' do
        test_module.backend :delayed_job
        Delayed::Job.expects(:enqueue).with(worker, :queue => nil)
        test_module.enqueue_for_backend TestWorker, 'FakeClass', 1, :image
      end

      it 'sets the queue name to the queue name passed to #backend' do
        test_module.backend :delayed_job, :queue => :awesome_queue
        Delayed::Job.expects(:enqueue).with(worker, :queue => :awesome_queue)
        test_module.enqueue_for_backend TestWorker, 'FakeClass', 1, :image
      end
    end

    context 'resque' do
      let(:args) { [TestWorker, 'FakeClass', 1, :image] }
      before do
        Resque.expects(:enqueue).with(*args)
      end

      it 'sets a variable with the queue name, defaults to :carrierwave' do
        test_module.backend :resque
        test_module.enqueue_for_backend(*args)
        expect(TestWorker.instance_variable_get '@queue').to eql(:carrierwave)
      end

      it 'sets a variable to the queue name passed to #backend' do
        test_module.backend :resque, :queue => :awesome_queue
        test_module.enqueue_for_backend(*args)
        expect(TestWorker.instance_variable_get '@queue').to eql(:awesome_queue)
      end
    end

    context 'sidekiq' do
      let(:args) { [TestWorker, 'FakeClass', 1, :image] }
      before do
        Sidekiq::Client.expects(:enqueue).with(*args)
      end

      it 'sets sidekiq_options to empty hash and calls enqueue with passed args' do
        TestWorker.expects(:sidekiq_options).with({})
        test_module.backend :sidekiq
        test_module.enqueue_for_backend(*args)
      end

      it 'sets sidekiq_options to the options passed to backend' do
        options = {:retry => false, :timeout => 60, :queue => :awesome_queue}
        TestWorker.expects(:sidekiq_options).with(options)
        test_module.backend :sidekiq, options
        test_module.enqueue_for_backend(*args)
      end
    end

    context 'girl_friday' do
      let(:args) { [TestWorker, 'FakeClass', 1, :image] }

      it 'instantiates a GirlFriday work queue if one does not exist' do
        test_module.backend :girl_friday
        GirlFriday::WorkQueue.expects(:new).with(:carrierwave, {}).returns([])
        test_module.enqueue_for_backend(*args)
      end

      it 'instantiates a GirlFriday work queue passing the args to the queue' do
        test_module.backend :girl_friday, :queue => :awesome_queue, :size => 3
        GirlFriday::WorkQueue.expects(:new).with(:awesome_queue, {:size => 3}).returns([])
        test_module.enqueue_for_backend(*args)
      end

      it 'does not instantiate a GirlFriday work queue if one exists' do
        test_module.backend :girl_friday
        test_module.instance_variable_set('@girl_friday_queue', [])
        GirlFriday::WorkQueue.expects(:new).never
        test_module.enqueue_for_backend(*args)
      end

      it 'add a worker to the girl_friday queue' do
        expected = [{ :worker => TestWorker.new('FakeClass', 1, :image) }]
        test_module.backend :girl_friday
        test_module.instance_variable_set('@girl_friday_queue', [])
        test_module.enqueue_for_backend(*args)
        expect(test_module.instance_variable_get '@girl_friday_queue').to eql(expected)
      end
    end

    context 'qu' do
      let(:args) { [TestWorker, 'FakeClass', 1, :image] }
      before do
        Qu.expects(:enqueue).with(*args)
      end

      it 'sets a variable with the queue name, defaults to :carrierwave' do
        test_module.backend :qu
        test_module.enqueue_for_backend(*args)
        expect(TestWorker.instance_variable_get '@queue').to eql(:carrierwave)
      end

      it 'sets a variable to the queue name passed to #backend' do
        test_module.backend :qu, :queue => :awesome_queue
        test_module.enqueue_for_backend(*args)
        expect(TestWorker.instance_variable_get '@queue').to eql(:awesome_queue)
      end
    end

    context 'qc' do
      it 'calls enqueue with the passed args' do
        QC.expects(:enqueue).with("TestWorker.perform", 'FakeClass', 1, 'image')
        test_module.backend :qc
        test_module.enqueue_for_backend(TestWorker, 'FakeClass', 1, :image)
      end
    end

    context 'immediate' do
      it 'instantiates a worker passing the args and calls perform' do
        worker = mock('Worker')
        TestWorker.expects(:new).with('FakeClass', 1, :image).returns(worker)
        worker.expects(:perform)
        test_module.backend :immediate
        test_module.enqueue_for_backend(TestWorker, 'FakeClass', 1, :image)
      end
    end

  end
end

