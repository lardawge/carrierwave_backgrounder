module CarrierWave
  module Backgrounder
    module Support
      module Backends

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          attr_reader :queue_options

          def backend(backend_name=nil, args={})
            return @backend if @backend
            @queue_options = args
            @backend = backend_name
          end

          def enqueue_for_backend(worker, class_name, subject_id, mounted_as)
            self.send :"enqueue_#{backend}", worker, class_name, subject_id, mounted_as
          end

          private

          def enqueue_active_job(worker, *args)
            # ActiveJob::QueueName.queue_as sets worker's :queue_name class_attribute,
            # and it has higher priority than globally-configured queue name.
            # If :queue_as is not set, :queue_name is ActiveJob::QueueName's default Proc.
            if !(worker.queue_name == 'default' || worker.queue_name.nil?)
              queue_options.delete(:queue)
            end

            worker.set(queue_options).perform_later(*args.map(&:to_s))
          end

          def enqueue_sidekiq(worker, *args)
            override_queue_name = worker.sidekiq_options['queue'] == 'default' || worker.sidekiq_options['queue'].nil?
            args = sidekiq_queue_options(override_queue_name, 'class' => worker, 'args' => args.map(&:to_s))
            worker.client_push(args)
          end

          private

          def sidekiq_queue_options(override_queue_name, args)
            if override_queue_name && queue_options[:queue]
              args['queue'] = queue_options[:queue]
            end
            args['retry'] = queue_options[:retry] unless queue_options[:retry].nil?
            args['timeout'] = queue_options[:timeout] if queue_options[:timeout]
            args['backtrace'] = queue_options[:backtrace] if queue_options[:backtrace]
            args
          end
        end
      end
    end
  end
end
