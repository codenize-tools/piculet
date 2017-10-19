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

        if @options.dry_run
          sg = OpenStruct.new({:id => '<new security group>', :group_name => name, :vpc_id => opts[:vpc], :tags => {}}.merge(opts))
        else
          args = { :group_name => name, :vpc_id => opts[:vpc], :description => opts[:description] }
          sg = @options.ec2.create_security_group(args)
          @options.updated = true
        end

        SecurityGroup.new(sg, @options)
      end
    end # SecurityGroupCollection
  end # EC2Wrapper
end # Piculet
