module Piculet
  class Logger < ::Logger
    include Singleton

    def initialize
      super($stdout)

      self.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end

      self.level = Logger::INFO
    end

    def set_debug(value)
      self.level = value ? Logger::DEBUG : Logger::INFO
    end

    module ClientHelper
      def log(level, message, color, log_id = nil)
        message = "[#{level.to_s.upcase}] #{message}" unless level == :info
        message << ": #{log_id}" if log_id
        message << ' (dry-run)' if @options && @options.dry_run
        logger = (@options && @options.logger) || Piculet::Logger.instance
        message = message.send(color) if color
        logger.send(level, message)
      end
    end # ClientHelper
  end # Logger
end # Piculet
