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

        def eql?(dsl)
          description_eql?(dsl) and tags_eql?(dsl)
        end

        def update(dsl)
          unless description_eql?(dsl)
            log(:warn, '`description` cannot be updated', :yellow, "#{vpc_id || :classic} > #{name}")
          end

          unless tags_eql?(dsl)
            log(:info, 'Update SecurityGroup', :green, "#{vpc_id || :classic} > #{name}")
            update_tags(dsl)
          end
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

        def tags
          h = {}
          @security_group.tags.map {|k, v| h[k] = v }
          h
        end

        def ingress_ip_permissions
          PermissionCollection.new(@security_group, :ingress, @options)
        end

        def egress_ip_permissions
          PermissionCollection.new(@security_group, :egress, @options)
        end

        private
        def description_eql?(dsl)
          @security_group.description == dsl.description
        end

        def tags_eql?(dsl)
          self_tags = normalize_tags(self.tags)
          dsl_tags = normalize_tags(dsl.tags)
          self_tags == dsl_tags
        end

        def update_tags(dsl)
          self_tags = normalize_tags(self.tags)
          dsl_tags = normalize_tags(dsl.tags)

          log(:info, "  tags:\n".green + Piculet::Utils.diff(self_tags, dsl_tags, :color => @options.color, :indent => '    '), false)

          unless @options.dry_run
            if dsl_tags.empty?
              @security_group.tags.clear
            else
              delete_keys = self_tags.keys - dsl_tags.keys
              # XXX: `delete` method does not remove the tag. It's seems a bug in the API
              #@security_group.tags.delete(delete_keys) unless delete_keys.empty?
              @security_group.tags.clear unless delete_keys.empty?
              @security_group.tags.set(dsl_tags)
            end

            @options.updated = true
          end
        end

        def normalize_tags(src)
          normalized = {}
          src.map {|k, v| normalized[k.to_s] = v.to_s }
          normalized
        end
      end # SecurityGroup
    end # SecurityGroupCollection
  end # EC2Wrapper
end # Piculet
