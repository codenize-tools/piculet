require 'ostruct'
require 'piculet/logger'
require 'piculet/wrapper/security-group'

module Piculet
  class EC2Wrapper
    class SecurityGroupCollection
      include Logger::ClientHelper

      def initialize(security_groups, options)
        @security_groups = security_groups
        @options = options
      end

      def each
        @security_groups.each do |sg|
          yield(SecurityGroup.new(sg, @options))
        end
      end

      def create(name, opts = {})
        log(:info, 'Create SecurityGroup', :cyan, "#{opts[:vpc] || :classic} > #{name}")
        log(:warn, '`egress any 0.0.0.0/0` is implicitly defined', :yellow) if @options.dry_run && opts[:vpc]

        if @options.dry_run
          sg = OpenStruct.new({:id => '<new security group>', :name => name}.merge(opts))
        else
          sg = @security_groups.create(name, opts)
          @options.updated = true
        end

        SecurityGroup.new(sg, @options)
      end
    end # SecurityGroupCollection
  end # EC2Wrapper
end # Piculet
