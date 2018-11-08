module Piculet
  class EC2Wrapper
    class SecurityGroupCollection
      class SecurityGroup
        extend Forwardable
        include Logger::ClientHelper

        def_delegators(
          :@security_group,
# <<<<<<< HEAD
#           :vpc_id, :name)
# =======
          :vpc_id, :group_name)
#>>>>>>> Upgrade aws-sdk to v2

        def initialize(security_group, options)
          @security_group = security_group
          @options = options
        end

        def eql?(dsl)
          description_eql?(dsl) and tags_eql?(dsl)
        end

        def update(dsl)
          unless description_eql?(dsl)
            log(:warn, '`description` cannot be updated', :yellow, "#{vpc_id || :classic} > #{group_name}")
          end

          unless tags_eql?(dsl)
            log(:info, 'Update SecurityGroup', :green, "#{vpc_id || :classic} > #{group_name}")
            update_tags(dsl)
          end
        end

        def delete
          log(:info, 'Delete SecurityGroup', :red, "#{vpc_id || :classic} > #{group_name}")

          if group_name == 'default'
            log(:warn, 'SecurityGroup `default` is reserved', :yellow)
          else
            unless @options.dry_run
              @security_group.delete
              @options.updated = true
            end
          end
        end

        def vpc?
          !!@security_group
        end

        def tags
          h = {}
          @security_group.tags.map {|tag| h[tag.key] = tag.value }
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
            client = @security_group.client
            id = @security_group.id
            client.delete_tags(resources: [ id ], tags: [])
            client.create_tags(resources: [ id ], tags: dsl_tags)

            @options.updated = true
          end
        end

        def normalize_tags(src)
          normalized = []
          src.map {|k, v| normalized << { key: k.to_s, value: v.to_s } }
          normalized
        end
      end # SecurityGroup
    end # SecurityGroupCollection
  end # EC2Wrapper
end # Piculet
