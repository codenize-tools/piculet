require 'piculet/wrapper/security-group-collection'

module Piculet
  class EC2Wrapper
    def initialize(ec2, options)
      @ec2 = ec2
      @options = options
    end

    def security_groups
      SecurityGroupCollection.new(@ec2.security_groups, @options)
    end
  end # EC2Wrapper
end # Piculet
