module Piculet
  class DSL
    class EC2
      class SecurityGroup
        include Logger::ClientHelper
        include Piculet::TemplateHelper

        def initialize(context, name, vpc, &block)
          @name = name
          @vpc = vpc
          @context = context.merge(:security_group_name => name)

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

          @result.ingress = Permissions.new(@context, @name, :ingress, &block).result
          rule_cnt = @result.ingress.reduce(0) {
            |sum , o|
            sum +
              (o.ip_ranges.nil? ? 0 : o.ip_ranges.length()) +
              (o.groups.nil? ? 0 : o.groups.length())
          }
          if rule_cnt > 50
            log(:warn, "`#{@vpc}.#{@name}`: ingress too many #{rule_cnt} " , :yellow)
          end
          @ingress_is_defined = true
        end

        def egress(&block)
          if @egress_is_defined
            raise "SecurityGroup `#{@name}`: `egress` is already defined"
          end

          unless @vpc
            raise "SecurityGroup `#{@name}`: Cannot define `egress` in classic"
          end

          @result.egress = Permissions.new(@context, @name, :egress, &block).result
          rule_cnt = @result.egress.reduce(0) {
            |sum , o|
            sum +
              (o.ip_ranges.nil? ? 0 : o.ip_ranges.length()) +
              (o.groups.nil? ? 0 : o.groups.length())
          }
          if rule_cnt > 50
            log(:warn, "`#{@vpc}.#{@name}`: egress too many #{rule_cnt} " , :yellow)
          end
          @egress_is_defined = true
        end
      end # SecurityGroup
    end # EC2
  end # DSL
end # Piculet
