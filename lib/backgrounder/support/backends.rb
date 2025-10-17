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
            @queue_options = set_queue_name_default(args)
            @backend = backend_name
          end

          def enqueue_for_backend(worker, class_name, subject_id, mounted_as)
            self.send :"enqueue_#{backend}", worker, class_name, subject_id, mounted_as
          end

          private

          def enqueue_active_job(worker, *args)
            options = if worker.new.queue_name != 'default'
              queue_options.except(:queue)
            else
              queue_options
            end

            worker.set(options).perform_later(*args.map(&:to_s))
          end

          def enqueue_sidekiq(worker, *args)
            override_queue_name = worker.sidekiq_options['queue'] == 'default'
            args = sidekiq_queue_options(override_queue_name, 'class' => worker, 'args' => args.map(&:to_s))
            worker.client_push(args)
          end

          private

          def set_queue_name_default(options)
            options.tap do |opts|
              opts[:queue] ||= :carrierwave
            end
          end

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
