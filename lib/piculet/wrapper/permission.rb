module Piculet
  class EC2Wrapper
    class SecurityGroupCollection
      class SecurityGroup
        class PermissionCollection
          class Permission
            extend Forwardable
            include Logger::ClientHelper

            def_delegators(
              :@permission,
              :from_port, :to_port, :ip_ranges, :groups)

            def initialize(permission, collection, options)
              @permission = permission
              @collection = collection
              @options = options
            end

            def ip_protocol
              @permission.ip_protocol == "-1" ? :any : @permission.ip_protocol.to_sym
            end

            def eql?(dsl)
              dsl_ip_ranges, dsl_groups, self_ip_ranges, self_groups = normalize_attrs(dsl)
              (self_ip_ranges == dsl_ip_ranges) and (self_groups == dsl_groups)
            end

            def update(dsl)
              log(:info, 'Update Permission', :green, log_id)

              plus_ip_ranges, minus_ip_ranges, plus_groups, minus_groups = diff(dsl)

              unless (plus_ip_ranges + plus_groups).empty?
                @collection.authorize(ip_protocol, port_range, (plus_ip_ranges + plus_groups), :log_color => :green)
              end

              unless (minus_ip_ranges + minus_groups).empty?
                @collection.revoke(ip_protocol, port_range, (minus_ip_ranges + minus_groups), :log_color => :green)
              end
            end

            def delete
              log(:info, 'Delete Permission', :red, log_id)

              self_ip_ranges, self_groups = normalize_self_attrs([])

              unless (self_ip_ranges + self_groups).empty?
                @collection.revoke(ip_protocol, port_range, (self_ip_ranges + self_groups), :log_color => :red)
              end
            end

            def port_range
              range = from_port..to_port
              if range == (nil..nil)
                range = nil
              end
              range
            end

            private
            def log_id
              "#{@collection.log_id} > #{ip_protocol} #{port_range}"
            end

            def diff(dsl)
              dsl_ip_ranges, dsl_groups, self_ip_ranges, self_groups = normalize_attrs(dsl)

              [
                dsl_ip_ranges - self_ip_ranges,
                self_ip_ranges - dsl_ip_ranges,
                dsl_groups - self_groups,
                self_groups - dsl_groups,
              ]
            end

            def normalize_attrs(dsl)
              dsl_ip_ranges = (dsl.ip_ranges || []).sort
              dsl_groups = (dsl.groups || []).map {|i|
                if i.kind_of?(Array)
                  i
                elsif Aws::EC2::SecurityGroup.elb?(i)
                  [Aws::EC2::SecurityGroup::ELB_OWNER, Aws::EC2::SecurityGroup::ELB_NAME]
                else
                  [@options.ec2.owner_id, i]
                end
              }.sort

              self_ip_ranges, self_groups = normalize_self_attrs(dsl_groups.map { |g| g[1] })

              [dsl_ip_ranges, dsl_groups, self_ip_ranges, self_groups]
            end

            def normalize_self_attrs(dsl_group_names)
              self_ip_ranges = @permission.ip_ranges.map { |range| range.cidr_ip }.sort
              self_groups = (@permission.user_id_group_pairs || []).map {|i|
                if dsl_group_names.include?(i.group_id)
                  [i.user_id, i.group_id]
                else
                  group = @options.ec2.security_groups.find { |g| g.id == i.group_id }
                  [i.user_id, group.group_name]
                end
              }.sort

              [self_ip_ranges, self_groups]
            end
          end # Permission
        end # PermissionCollection
      end # SecurityGroup
    end # SecurityGroupCollection
  end # EC2Wrapper
end # Piculet
