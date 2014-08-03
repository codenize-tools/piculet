module AWS
  class EC2
    class SecurityGroup
      AMAZON_ELB_SG_OWNER = 'amazon-elb'
      AMAZON_ELB_SG_NAME = 'amazon-elb-sg'

      def elb?
        self.owner_id == AMAZON_ELB_SG_OWNER
      end

      alias name_orig name

      def name
        self.elb? ? AMAZON_ELB_SG_NAME : name_orig
      end
    end # SecurityGroup
  end # EC2
end # AWS
