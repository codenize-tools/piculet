require 'piculet/dsl/permissions'

module Piculet
  class DSL
    class EC2
      class SecurityGroup
        def initialize(name, &block)
          @name = name

          @result = OpenStruct.new({
            :name    => name,
            :ingress => [],
            :egress  => [],
          })

          instance_eval(&block)
        end

        def result
          unless @result.description
            raise "SecurityGroup `#{@name}`: `description` is required"
          end

          @result
        end

        private
        def description(value)
          @result.description = value
        end

        def ingress(&block)
          @result.ingress << Permissions.new(@name, :ingress, &block).result
        end

        def egress(&block)
          @result.egress << Permissions.new(@name, :egress, &block).result
        end
      end # SecurityGroup
    end # EC2
  end # DSL
end # Piculet
