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
      test_module.available_backends.should include(:girl_friday)
    end

    it 'detects Delayed::Job' do
      test_module.available_backends.should include(:delayed_job)
    end
    
    it 'detects Resque' do
      test_module.available_backends.should include(:resque)
    end
    
    it 'detects Qu' do
      test_module.available_backends.should include(:qu)
    end
    
    it 'detects Sidekiq' do
      test_module.available_backends.should include(:sidekiq)
    end
    
    it 'detects QC' do
      test_module.available_backends.should include(:qc)
    end

    it 'detects Immediate' do
      test_module.available_backends.should include(:immediate)
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
      test_module.backend.should eq(:qu)
    end
    
    it 'raises an error if more than one backend is available' do
      test_module.stubs(:available_backends).returns([:qu, :resque])
      expect {
       test_module.backend
      }.to raise_error(CarrierWave::Backgrounder::ToManyBackendsAvailableError)
    end

    it 'does not clobber a manually set backend' do
      test_module.backend = :not_a_backend
      test_module.backend.should eq(:not_a_backend)
    end
  end

  describe '#enqueue_for_backend' do
    context 'delayed_job' do
      it 'defaults the queue name to nil if none passed' do
        test_module.backend :delayed_job
        worker = TestWorker.new('FakeClass', 1, :image)
        TestWorker.stubs(:new).returns(worker)
        Delayed::Job.expects(:enqueue).with(worker, :queue => nil)
        test_module.enqueue_for_backend TestWorker, 'FakeClass', 1, :image
      end

      it 'sets the queue name to the queue arg' do
        test_module.backend :delayed_job, :queue => :awesome_queue
        worker = TestWorker.new('FakeClass', 1, :image)
        TestWorker.stubs(:new).returns(worker)
        Delayed::Job.expects(:enqueue).with(worker, :queue => :awesome_queue)
        test_module.enqueue_for_backend TestWorker, 'FakeClass', 1, :image
      end
    end
  end
end

