IPv4_CIDR = /^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/
IPV6_CIDR = /^s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\/([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-8]))?$/

module Piculet
  class DSL
    class EC2
      class SecurityGroup
        class Permissions
          class Permission
            include Piculet::TemplateHelper

            def initialize(context, security_group, direction, protocol_prot_range, &block)
              @security_group = security_group
              @direction = direction
              @protocol_prot_range = protocol_prot_range

              @context = context.merge(
                :protocol => protocol_prot_range[0],
                :port_range => protocol_prot_range[1]
              )

              @result = OpenStruct.new
              instance_eval(&block)
            end

            def result
              unless @result.ip_ranges or @result.groups
                raise "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `ip_ranges` or `groups` is required"
              end

              @result
            end

            private
            def ip_ranges(*values)
              if values.empty?
                raise ArgumentError, "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `ip_ranges`: wrong number of arguments (0 for 1..)"
              end

              values.each do |ip_range|
                unless ip_range =~ IPv4_CIDR or ip_range =~ IPV6_CIDR
                  raise "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `ip_ranges`: invalid ip range: #{ip_range}"
                end

                ip, range = ip_range.split('/', 2)
                
                begin
                  parsed_ipaddr = IPAddr.new(ip_range)

                  if ip != parsed_ipaddr.to_s
                    raise "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `ip_ranges`: invalid ip range: #{ip_range} correct #{parsed_ipaddr.to_s}/#{range}"
                  end
                rescue => e
                  raise "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `ip_ranges`: #{ip_range}: #{e.message}"
                end
              end

              if values.size != values.uniq.size
                raise "SecurityGroup `#{@security_group}\: #{@direction}: #{@protocol_prot_range}: `ip_ranges`: duplicate ip ranges"
              end

              @result.ip_ranges = values
            end

            def groups(*values)
              if values.empty?
                raise ArgumentError, "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `groups`: wrong number of arguments (0 for 1..)"
              end

              values.each do |group|
                unless [String, Array].any? {|i| group.kind_of?(i) }
                  raise "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `groups`: invalid type: #{group}"
                end
              end

              if values.size != values.uniq.size
                raise "SecurityGroup `#{@security_group}\: #{@direction}: #{@protocol_prot_range}: `groups`: duplicate groups"
              end

              @result.groups = values
            end
          end # Permission
        end # Permissions
      end # SecurityGroup
    end # EC2
  end # DSL
end # Piculet
