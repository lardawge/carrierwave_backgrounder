require 'spec_helper'
require 'support/backend_constants'
require 'support/mock_worker'

module CarrierWave::Backgrounder
  describe Support::Backends do
    let(:mock_module) { Module.new }

    before do
      mock_module.send :include, Support::Backends
    end

    describe 'setting backend' do
      it 'using #backend=' do
        expect {
          mock_module.backend = :delayed_job
        }.to raise_error(NoMethodError)
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

    describe '#enqueue_for_backend' do
      let!(:worker) { MockWorker.new('FakeClass', 1, :image) }

      context 'delayed_job' do
        before do
          @mock_worker = Class.new do
            def self.perform(*args); new(*args).perform; end
          end

          MockWorker.expects(:new).returns(worker)
        end

        context 'queue column exists' do
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

        context 'queue column does not exist' do
          before do
            column_names = Delayed::Job.column_names.tap { |cn| cn.delete('queue') }
            Delayed::Job.stubs(:column_names).returns(column_names)
            Delayed::Job.class_eval { remove_method(:queue) }
          end

          after do
            Delayed::Job.class_eval { define_method(:queue) { nil } }
          end

          it 'does not pass a queue name if none passed to #backend' do
            mock_module.backend :delayed_job
            Delayed::Job.expects(:enqueue).with(worker)
            mock_module.enqueue_for_backend MockWorker, 'FakeClass', 1, :image
          end

          it 'does not pass a queue name and logs a warning message if a queue name is passed to #backend' do
            mock_module.backend :delayed_job, :queue => :awesome_queue
            Delayed::Job.expects(:enqueue).with(worker)
            Rails.logger.expects(:warn).with(instance_of(String))
            mock_module.enqueue_for_backend MockWorker, 'FakeClass', 1, :image
          end
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
        let(:args) { ['FakeClass', 1, :image] }

        it 'invokes client_push on the class with passed args' do
          MockSidekiqWorker.expects(:client_push).with({ 'class' => MockSidekiqWorker, 'args' => args })
          mock_module.backend :sidekiq
          mock_module.enqueue_for_backend(MockSidekiqWorker, *args)
        end

        it 'invokes client_push and includes the options passed to backend' do
          MockSidekiqWorker.expects(:client_push).with({ 'class' => MockSidekiqWorker, 
                                                         'retry' => false,
                                                         'timeout' => 60,
                                                         'queue' => :awesome_queue,
                                                         'args' => args })
          options = {:retry => false, :timeout => 60, :queue => :awesome_queue}
          mock_module.backend :sidekiq, options
          mock_module.enqueue_for_backend(MockSidekiqWorker, *args)
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

      context 'sucker_punch' do
        let(:args) { [MockWorker, 'FakeClass', 1, :image] }
        let(:job) { mock('job') }

        it 'invokes a new worker' do
          MockWorker.expects(:new).returns(worker)
          worker.expects(:async).returns(job)
          job.expects(:perform).with('FakeClass', 1, :image)
          mock_module.backend :sucker_punch
          mock_module.enqueue_for_backend(*args)
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
end
