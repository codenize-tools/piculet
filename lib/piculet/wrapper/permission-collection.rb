module Piculet
  class EC2Wrapper
    class SecurityGroupCollection
      class SecurityGroup
        class PermissionCollection
          include Logger::ClientHelper

          def initialize(security_group, direction, options)
            @security_group = security_group
            case direction
            when :ingress
              @permissions = security_group.ip_permissions
            when :egress
              @permissions = security_group.ip_permissions_egress
            end
            @direction = direction
            @options = options
          end

          def each
            perm_list = @permissions || []

            perm_list.each do |perm|
              yield(Permission.new(perm, self, @options))
            end
          end

          def authorize(protocol, ports, sources, opts = {})
            log(:info, "  authorize #{format_sources(sources)}", opts.fetch(:log_color, :green))

            unless @options.dry_run
              sources = normalize_sources(sources)

              case @direction
              when :ingress
                params = permission_params(protocol, ports, sources)
                @security_group.authorize_ingress(params)
                @options.updated = true
              when :egress
                sources.push(:protocol => protocol, :ports => ports)
                params = permission_params(protocol, ports, sources)
                @security_group.authorize_egress(params)
                @options.updated = true
              end
            end
          end

          def revoke(protocol, ports, sources, opts = {})
            log(:info, "  revoke #{format_sources(sources)}", opts.fetch(:log_color, :green))

            unless @options.dry_run
              sources = normalize_sources(sources)

              case @direction
              when :ingress
                params = permission_params(protocol, ports, sources)
                @security_group.revoke_ingress(params)
                @options.updated = true
              when :egress
                sources.push(:protocol => protocol, :ports => ports)
                params = permission_params(protocol, ports, sources)
                @security_group.revoke_egress(params)
                @options.updated = true
              end
            end
          end

          def create(protocol, port_range, dsl)
            dsl_ip_ranges = dsl.ip_ranges || []
            dsl_groups = (dsl.groups || []).map do |i|
              i.kind_of?(Array) ? i : [@options.ec2.owner_id, i]
            end

            sources = dsl_ip_ranges + dsl_groups

            unless sources.empty?
              log(:info, 'Create Permission', :cyan, "#{log_id} > #{protocol} #{port_range}")
              authorize(protocol, port_range, sources, :log_color => :cyan)
            end
          end

          def log_id
            vpc = @security_group.vpc_id || :classic
            name = @security_group.group_name

            if @security_group.owner_id and not @options.ec2.own?(@security_group.owner_id)
              name = "#{@security_group.owner_id}/#{name}"
            end

            "#{vpc} > #{name}(#{@direction})"
          end

          private
          def normalize_sources(sources)
            normalized = []

            sources.each do |src|
              case src
              when String
                normalized << src
              when Array
                owner_id, group = src

                if src.any? {|i| Aws::EC2::SecurityGroup.elb?(i) }
                  normalized << {
                    :user_id    => Aws::EC2::SecurityGroup::ELB_OWNER,
                    :group_name => Aws::EC2::SecurityGroup::ELB_NAME
                  }
                else
                  unless group =~ /\Asg-[0-9a-f]+\Z/
                    sg_coll = @options.ec2.security_groups.select { |sg| sg.group_name == group }

                    if @options.ec2.own?(owner_id)
                      sg_coll = sg_coll.select { |sg| sg.vpc_id == @security_group.vpc_id } if @security_group.vpc?
                    else
                      sg_coll = sg_coll.select { |sg| sg.owner_id == @security_group.owner_id }
                    end

                    unless (sg = sg_coll.first)
                      raise "Can't find SecurityGroup: #{owner_id}/#{group} in #{@security_group.vpc_id || :classic}"
                    end

                    group = sg.id
                  end

                  normalized << {:user_id => owner_id, :group_id => group}
                end
              end
            end

            return normalized
          end

          def format_sources(sources)
            sources.map {|src|
              if src.kind_of?(Array)
                owner_id, group = src
                dst = [group]
                dst.unshift(owner_id) unless @options.ec2.own?(owner_id)
                dst.join('/')
              else
                src
              end
            }.join(', ')
          end

          def permission_params(protocol, ports, sources)
            ip_protocol = protocol == :any ? "-1" : protocol.to_sym
            ports = ports || (-1..-1)

            ip_permissions = []
            sources.each do |source|
              permission = { ip_protocol: ip_protocol, from_port: ports.begin, to_port: ports.end }
              if valid_ip?(source)
                permission.merge!({ ip_ranges: [ { cidr_ip: source } ] })
              else
                permission.merge!({ user_id_group_pairs: [ { group_id: source[:group_id] } ] })
              end
              ip_permissions << Aws::EC2::Types::IpPermission.new(permission)
            end

            { ip_permissions: ip_permissions }
          end

          def valid_ip?(str)
            !!IPAddr.new(str) rescue false
          end
        end # PermissionCollection
      end # SecurityGroup
    end # SecurityGroupCollection
  end # EC2Wrapper
end # Piculet
