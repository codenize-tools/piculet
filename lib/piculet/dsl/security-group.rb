module Piculet
  class DSL
    class EC2
      class SecurityGroup
        def initialize(name, vpc, &block)
          @name = name
          @vpc = vpc

          @result = OpenStruct.new({
            :name    => name,
            :tags    => {},
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

        def tags(values)
          if @tags_is_defined
            raise "SecurityGroup `#{@name}`: `tags` is already defined"
          end

          unless values.kind_of?(Hash)
            raise "SecurityGroup `#{@name}`: argument of `tags` is wrong (expected Hash)"
          end

          @result.tags = values
          @tags_is_defined = true
        end

        def ingress(&block)
          if @ingress_is_defined
            raise "SecurityGroup `#{@name}`: `ingress` is already defined"
          end

          @result.ingress = Permissions.new(@name, :ingress, &block).result
          @ingress_is_defined = true
        end

        def egress(&block)
          if @egress_is_defined
            raise "SecurityGroup `#{@name}`: `egress` is already defined"
          end

          unless @vpc
            raise "SecurityGroup `#{@name}`: Cannot define `egress` in classic"
          end

          @result.egress = Permissions.new(@name, :egress, &block).result

          @egress_is_defined = true
        end
      end # SecurityGroup
    end # EC2
  end # DSL
end # Piculet
