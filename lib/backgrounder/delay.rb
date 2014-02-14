module CarrierWave
  module Backgrounder

    module Delay
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        ##
        # Adds a processor callback which applies operations as a file is uploaded.
        # The argument may be the name of any method of the uploader, expressed as a symbol,
        # or a list of such methods, or a hash where the key is a method and the value is
        # an array of arguments to call the method with
        #
        # === Parameters
        #
        # args (*Symbol, Hash{Symbol => Array[]})
        #
        # === Examples
        #
        #     class MyUploader < CarrierWave::Uploader::Base
        #
        #       process :sepiatone, :vignette
        #       process :scale => [200, 200]
        #       process :scale => [200, 200], :if => :image?
        #       process :sepiatone, :if => :image?, :do_not_delay => true
        #
        #       def sepiatone
        #         ...
        #       end
        #
        #       def vignette
        #         ...
        #       end
        #
        #       def scale(height, width)
        #         ...
        #       end
        #
        #       def image?
        #         ...
        #       end
        #
        #     end
        #
        def process(*args)
          if !args.first.is_a?(Hash) && args.last.is_a?(Hash)
            conditions = args.pop
            args.map!{ |arg| {arg => []}.merge(conditions) }
          end

          args.each do |arg|
            if arg.is_a?(Hash)
              condition = arg.delete(:if)
              do_not_delay = arg.delete :do_not_delay
              do_not_delay = version_options.key?(:do_not_delay) ?
                             version_options[:do_not_delay] : do_not_delay
              arg.each do |method, args|
                self.processors += [[method, args, condition, do_not_delay]]
              end
            else
              self.processors += [[arg, [], nil]]
            end
          end
        end

        ##
        # Returns the parent Uploader unless self is topmost
        #
        def parent_uploader
          superclass == CarrierWave::Uploader::Base ? self : superclass
        end

        ##
        # Returns the options passed to the :version clause in the uploader.
        # Here is used the fact that at the moment the method is called
        # the latest version is the current one.
        #
        def version_options
          parent_uploader.versions.values.last[:options] rescue {}
        end

        ##
        # If the uploader belongs to a version, returns negation of its option :do_not_delay.
        # For the root uploader returns true if any of clauses :process
        # or any of version has not option :do_not_delay.
        #
        def delay?
          hash = parent_uploader.versions.values.detect do |hash|
            hash[:uploader] == self
          end
          not hash[:options][:do_not_delay]
        rescue
          processors.any? do |method, args, condition, do_not_delay|
            not do_not_delay    # == delay
          end or
          versions.values.any? do |hash|
            not hash[:options][:do_not_delay]   # == delay
          end
        end

        ##
        # If the uploader belongs to a version, returns its option :do_not_delay.
        # For the root uploader returns true if any clause :process has this option.
        #
        def do_not_delay?
          hash = parent_uploader.versions.values.detect do |hash|
            hash[:uploader] == self
          end
          hash[:options][:do_not_delay]
        rescue
          processors.any? do |method, args, condition, do_not_delay|
            do_not_delay
          end
        end
      end # ClassMethods

      def cache_versions!(new_file)
        super if proceed_with_versioning?
      end

      def store_versions!(*args)
        super if proceed_with_versioning?
      end

      ##
      # Apply all process callbacks added through CarrierWave.process
      #
      def process!(new_file=nil)
        if enable_processing
          self.class.processors.each do |method, args, condition, do_not_delay|
            next unless proceed_with_versioning?(!!do_not_delay)
            if condition
              next if !(condition.respond_to?(:call) ? condition.call(self, :args => args, :method => method, :file => new_file) : self.send(condition, new_file))
            end
            self.send(method, *args)
          end
        end
      end

      private

      def proceed_with_versioning?(do_not_delay = nil)
        delay, do_not_delay =
            if do_not_delay.nil?
              [self.class.delay?, self.class.do_not_delay?]
            else
              [!do_not_delay, do_not_delay]
            end
        !model.respond_to?(:"process_#{mounted_as}_upload") || model.send(:"process_#{mounted_as}_upload") && delay || !model.send(:"process_#{mounted_as}_upload") && do_not_delay
      end
    end # Delay

  end # Backgrounder
end # CarrierWave
