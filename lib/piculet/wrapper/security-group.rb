require 'forwardable'
require 'piculet/logger'
require 'piculet/wrapper/permission-collection'

module Piculet
  class EC2Wrapper
    class SecurityGroupCollection
      class SecurityGroup
        extend Forwardable
        include Logger::ClientHelper

        def_delegators(
          :@security_group,
          :vpc_id, :name, :vpc?)

        def initialize(security_group, options)
          @security_group = security_group
          @options = options
        end

        def delete
          log(:info, 'Delete SecurityGroup', :red, "#{vpc_id || :classic} > #{name}")

          if name == 'default'
            log(:warn, 'SecurityGroup `default` is reserved', :yellow)
          else
            unless @options.dry_run
              @security_group.delete
              @options.updated = true
            end
          end
        end

        def ingress_ip_permissions
          PermissionCollection.new(@security_group, :ingress, @options)
        end

        def egress_ip_permissions
          PermissionCollection.new(@security_group, :egress, @options)
        end
      end # SecurityGroup
    end # SecurityGroupCollection
  end # EC2Wrapper
end # Piculet
