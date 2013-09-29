require 'forwardable'
require 'piculet/logger'

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
              :protocol, :port_range, :ip_ranges, :groups)

            def initialize(permission, collection, options)
              @permission = permission
              @collection = collection
              @options = options
            end

            def eql?(dsl)
              dsl_ip_ranges, dsl_groups, self_ip_ranges, self_groups = normalize_attrs(dsl)
              (self_ip_ranges == dsl_ip_ranges) and (self_groups == dsl_groups)
            end

            def update(dsl)
              log(:info, 'Update Permission', :green, log_id)

              plus_ip_ranges, minus_ip_ranges, plus_groups, minus_groups = diff(dsl)

              unless (plus_ip_ranges + plus_groups).empty?
                @collection.authorize(protocol, port_range, *(plus_ip_ranges + plus_groups))
              end

              unless (minus_ip_ranges + minus_groups).empty?
                @collection.revoke(protocol, port_range, *(minus_ip_ranges + minus_groups))
              end
            end

            def delete
              log(:info, 'Delete Permission', :red, log_id)

              self_ip_ranges, self_groups = normalize_self_attrs

              unless (self_ip_ranges + self_groups).empty?
                @collection.revoke(protocol, port_range, *(self_ip_ranges + self_groups))
              end
            end

            private
            def log_id
              "#{@collection.log_id} > #{protocol} #{port_range}"
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
                i.kind_of?(Array) ? i : [@options.ec2.owner_id, i]
              }.sort

              self_ip_ranges, self_groups = normalize_self_attrs

              [dsl_ip_ranges, dsl_groups, self_ip_ranges, self_groups]
            end

            def normalize_self_attrs
              self_ip_ranges = (@permission.ip_ranges || []).sort
              self_groups = (@permission.groups || []).map {|i|
                [i.owner_id, i.name]
              }.sort

              [self_ip_ranges, self_groups]
            end
          end # Permission
        end # PermissionCollection
      end # SecurityGroup
    end # SecurityGroupCollection
  end # EC2Wrapper
end # Piculet
