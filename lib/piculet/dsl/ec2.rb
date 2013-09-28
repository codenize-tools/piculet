require 'piculet/dsl/security-group'

module Piculet
  class DSL
    class EC2
      attr_reader :result

      def initialize(vpc, &block)
        @result = OpenStruct.new({
          :vpc             => vpc,
          :security_groups => [],
        })

        instance_eval(&block)
      end

      private
      def security_group(name, &block)
        @result.security_groups << SecurityGroup.new(name, @result.vpc, &block).result
      end
    end # EC2
  end # DSL
end # Piculet
