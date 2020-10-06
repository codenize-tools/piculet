module Aws
  module EC2
    class SecurityGroup
      ELB_OWNER = 'amazon-elb'
      ELB_NAME = 'amazon-elb-sg'

      def elb?
        self.class.elb?(self.owner_id)
      end

      def vpc?
        vpc_id ? true : false
      end

      alias group_name_orig group_name

      def group_name
        self.elb? ? ELB_NAME : group_name_orig
      rescue Aws::EC2::Errors::InvalidGroupNotFound
        self.id
      end

      class << self
        def elb_sg
          "#{ELB_OWNER}/#{ELB_NAME}"
        end

        def elb?(owner_or_name)
          [ELB_OWNER, self.elb_sg].include?(owner_or_name)
        end
      end # of class methods
    end # SecurityGroup
  end # EC2
end # Aws
