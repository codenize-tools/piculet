module Piculet
  class DSL
    class EC2
      class SecurityGroup
        class Permissions
          class Permission
            def initialize(security_group, direction, protocol_prot_range, &block)
              @security_group = security_group
              @direction = direction
              @protocol_prot_range = protocol_prot_range
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
                unless ip_range =~ %r|\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}|
                  raise "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `ip_ranges`: invalid ip range: #{ip_range}"
                end

                ip, range = ip_range.split('/', 2)

                unless ip.split('.').all? {|i| (0..255).include?(i.to_i) } and (0..32).include?(range.to_i)
                  raise "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `ip_ranges`: invalid ip range: #{ip_range}"
                end
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

              @result.groups = values
            end
          end # Permission
        end # Permissions
      end # SecurityGroup
    end # EC2
  end # DSL
end # Piculet
