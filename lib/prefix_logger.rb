class Object

  class << self
    def prefix_logger(prefix, logger=Rails.logger)
      %w(debug info error warn fatal).each do |level|
        define_method "log_#{level}" do |*args, &block|
          message = args.any? ? args[0] : block.call
          logger.send(level.to_sym, "#{prefix}: #{message}")
        end
      end
      define_singleton_method "log_prefix" do |*args, &block|
        prefix
      end
    end
  end

end
