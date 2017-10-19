module Piculet
  class DSL
    class EC2
      class SecurityGroup
        class Permissions
          include Logger::ClientHelper
          include Piculet::TemplateHelper

          def initialize(context, security_group, direction, &block)
            @security_group = security_group
            @direction = direction
            @context = context.merge(:direction => direction)
            @result = {}
            instance_eval(&block)
          end

          def result
            @result.map do |key, perm|
              protocol, port_range = key

              OpenStruct.new({
                :ip_protocol => protocol,
                :port_range => port_range,
                :ip_ranges  => perm.ip_ranges,
                :groups     => perm.groups,
              })
            end
          end

          private
          def permission(protocol, port_range = nil, &block)
            if port_range
              if port_range.kind_of?(Integer)
                port_range = port_range..port_range
              elsif not port_range.kind_of?(Range)
                raise TypeError, "SecurityGroup `#{@security_group}`: #{@direction}: can't convert #{port_range} into Range"
              end
            end

            key = [protocol, port_range]
            res = Permission.new(@context, @security_group, @direction, key, &block).result

            if @result.has_key?(key)
              @result[key] = OpenStruct.new(@result[key].marshal_dump.merge(res.marshal_dump) {|hash_key, old_val, new_val|
                if (duplicated = old_val & new_val).any?
                  log(:warn, "SecurityGroup `#{@security_group}`: #{@direction}: #{key}: #{hash_key}: #{duplicated} are duplicated", :yellow)
                end

                old_val | new_val
              })
            else
              @result[key] = res
            end
          end
        end # Permissions
      end # SecurityGroup
    end # EC2
  end # DSL
end # Piculet
