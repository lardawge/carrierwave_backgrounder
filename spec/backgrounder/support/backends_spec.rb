require 'spec_helper'
require 'support/backend_constants'
require 'support/mock_worker'

module CarrierWave::Backgrounder
  RSpec.describe Support::Backends do
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

          allow(MockWorker).to receive(:new).and_return(worker)
        end

        context 'queue column exists' do
          it 'does not pass the queue name if none passed to #backend' do
            mock_module.backend :delayed_job
            expect(Delayed::Job).to receive(:enqueue).with(worker, {})
            mock_module.enqueue_for_backend MockWorker, 'FakeClass', 1, :image
          end

          it 'sets the queue name to the queue name passed to #backend' do
            mock_module.backend :delayed_job, :queue => :awesome_queue
            expect(Delayed::Job).to receive(:enqueue).with(worker, :queue => :awesome_queue)
            mock_module.enqueue_for_backend MockWorker, 'FakeClass', 1, :image
          end
        end

        context 'priority set in config' do
          it 'sets the priority which is passed to #backend' do
            mock_module.backend :delayed_job, :priority => 5
            expect(Delayed::Job).to receive(:enqueue).with(worker, :priority => 5)
            mock_module.enqueue_for_backend MockWorker, 'FakeClass', 1, :image
          end
        end

        context 'queue column does not exist' do
          before do
            column_names = Delayed::Job.column_names.tap { |cn| cn.delete('queue') }
            allow(Delayed::Job).to receive(:column_names).and_return(column_names)
            Delayed::Job.class_eval { remove_method(:queue) }
          end

          after do
            Delayed::Job.class_eval { define_method(:queue) { nil } }
          end

          it 'does not pass a queue name if none passed to #backend' do
            mock_module.backend :delayed_job
            expect(Delayed::Job).to receive(:enqueue).with(worker, {})
            mock_module.enqueue_for_backend MockWorker, 'FakeClass', 1, :image
          end

          it 'does not pass a queue name and logs a warning message if a queue name is passed to #backend' do
            mock_module.backend :delayed_job, :queue => :awesome_queue
            expect(Rails.logger).to receive(:warn).with(instance_of(String))
            expect(Delayed::Job).to receive(:enqueue).with(worker, {})
            mock_module.enqueue_for_backend MockWorker, 'FakeClass', 1, :image
          end
        end
      end

      context 'resque' do
        let(:args) { [MockWorker, 'FakeClass', 1, :image] }

        before do
          allow(Resque).to receive(:enqueue).with(*args)
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
          expect(MockSidekiqWorker).to receive(:client_push).with({ 'class' => MockSidekiqWorker, 'args' => args })
          mock_module.backend :sidekiq
          mock_module.enqueue_for_backend(MockSidekiqWorker, *args)
        end

        it 'invokes client_push and includes the options passed to backend' do
          expect(MockSidekiqWorker).to receive(:client_push).with({ 'class' => MockSidekiqWorker,
                                                                    'retry' => false,
                                                                    'timeout' => 60,
                                                                    'queue' => :awesome_queue,
                                                                    'args' => args })
          options = {:retry => false, :timeout => 60, :queue => :awesome_queue}
          mock_module.backend :sidekiq, options
          mock_module.enqueue_for_backend(MockSidekiqWorker, *args)
        end

        it 'does not override queue name if set it worker' do
          expect(MockNamedSidekiqWorker).to receive(:client_push).with({ 'class' => MockNamedSidekiqWorker,
                                                                    'retry' => false,
                                                                    'timeout' => 60,
                                                                    'args' => args })
          options = {:retry => false, :timeout => 60}
          mock_module.backend :sidekiq, options
          mock_module.enqueue_for_backend(MockNamedSidekiqWorker, *args)
        end
      end

      context 'girl_friday' do
        let(:args) { [MockWorker, 'FakeClass', 1, :image] }

        it 'instantiates a GirlFriday work queue if one does not exist' do
          mock_module.backend :girl_friday
          expect(GirlFriday::WorkQueue).to receive(:new).with(:carrierwave, {}).and_return([])
          mock_module.enqueue_for_backend(*args)
        end

        it 'instantiates a GirlFriday work queue passing the args to the queue' do
          mock_module.backend :girl_friday, :queue => :awesome_queue, :size => 3
          expect(GirlFriday::WorkQueue).to receive(:new).with(:awesome_queue, {:size => 3}).and_return([])
          mock_module.enqueue_for_backend(*args)
        end

        it 'does not instantiate a GirlFriday work queue if one exists' do
          mock_module.backend :girl_friday
          mock_module.instance_variable_set('@girl_friday_queue', [])
          expect(GirlFriday::WorkQueue).to receive(:new).never
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
        let(:job) { double('job') }

        it 'invokes a new worker' do
          expect(MockWorker).to receive(:new).and_return(worker)
          expect(worker).to receive(:async).and_return(job)
          expect(job).to receive(:perform).with('FakeClass', 1, :image)
          mock_module.backend :sucker_punch
          mock_module.enqueue_for_backend(*args)
        end
      end

      context 'qu' do
        let(:args) { [MockWorker, 'FakeClass', 1, :image] }
        before do
          allow(Qu).to receive(:enqueue).with(*args)
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
          expect(QC).to receive(:enqueue).with("MockWorker.perform", 'FakeClass', 1, 'image')
          mock_module.backend :qc
          mock_module.enqueue_for_backend(MockWorker, 'FakeClass', 1, :image)
        end
      end

      context 'immediate' do
        it 'instantiates a worker passing the args and calls perform' do
          worker = double('Worker')
          expect(MockWorker).to receive(:new).with('FakeClass', 1, :image).and_return(worker)
          expect(worker).to receive(:perform)
          mock_module.backend :immediate
          mock_module.enqueue_for_backend(MockWorker, 'FakeClass', 1, :image)
        end
      end
    end
  end
end
