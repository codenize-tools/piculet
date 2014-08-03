module AWS
  class EC2
    class SecurityGroup
      ELB_OWNER = 'amazon-elb'
      ELB_NAME = 'amazon-elb-sg'

      def elb?
        self.class.elb?(self.owner_id)
      end

      alias name_orig name

      def name
        self.elb? ? ELB_NAME : name_orig
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
end # AWS
