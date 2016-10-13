module Piculet
  class DSL
    class EC2
      include Piculet::TemplateHelper

      attr_reader :result

      def initialize(context, vpc, security_groups = [], &block)
        @names = Set.new
        @context = context.merge(:vpc => vpc)

        @result = OpenStruct.new({
          :vpc             => vpc,
          :security_groups => security_groups,
        })

        instance_eval(&block)
      end

      private
      def security_group(name, &block)
        if @names.include?(name)
          raise "EC2 `#{@result.vpc || :classic}`: `#{name}` is already defined"
        end

        @result.security_groups << SecurityGroup.new(@context, name, @result.vpc, &block).result
        @names << name
      end
    end # EC2
  end # DSL
end # Piculet
