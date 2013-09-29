require 'forwardable'
require 'ostruct'
require 'piculet/logger'
require 'piculet/ext/ip-permission-collection-ext'

module Piculet
  class EC2Wrapper
    def initialize(ec2, options)
      @ec2 = ec2
      @options = options
    end

    def security_groups
      SecurityGroupCollection.new(@ec2.security_groups, @options)
    end

    class SecurityGroupCollection ####################################
      include Logger::ClientHelper

      def initialize(security_groups, options)
        @security_groups = security_groups
        @options = options
      end

      def each
        @security_groups.each do |sg|
          yield(SecurityGroup.new(sg, @options))
        end
      end

      def create(name, opts = {})
        log(:info, 'Create SecurityGroup', :cyan, "#{opts[:vpc] || :classic} > #{name}")
        log(:warn, '`egress any 0.0.0.0/0` is implicitly defined', :yellow) if @options.dry_run && opts[:vpc]

        if @options.dry_run
          sg = OpenStruct.new({:name => name}.merge(opts))
        else
          sg = @security_groups.create(name, opts)
        end

        SecurityGroup.new(sg, @options)
      end

      class SecurityGroup ############################################
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
            @security_group.delete unless @options.dry_run
          end
        end

        def ingress_ip_permissions
          PermissionCollection.new(@security_group, :ingress, @options)
        end

        def egress_ip_permissions
          PermissionCollection.new(@security_group, :egress, @options)
        end

        class PermissionCollection ###################################
          include Logger::ClientHelper

          def initialize(security_group, direction, options)
            @security_group = security_group
            @permissions = security_group.send("#{direction}_ip_permissions")
            @direction = direction
            @options = options
          end

          def each
            perm_list = @permissions ? @permissions.aggregate : []

            perm_list.each do |perm|
              yield(Permission.new(perm, self, @options))
            end
          end

          def authorize(protocol, ports, *sources)
            log(:info, "  authorize #{format_sources(sources)}", :green)
            sources = normalize_sources(sources)

            case @direction
            when :ingress
              @security_group.authorize_ingress(protocol, ports, *sources)
            when :egress
              sources.push(:protocol => protocol, :ports => ports)
              @security_group.authorize_egress(*sources)
            end
          end

          def revoke(protocol, ports, *sources)
            log(:info, "  revoke #{format_sources(sources)}", :green)
            sources = normalize_sources(sources)

            case @direction
            when :ingress
              @security_group.revoke_ingress(protocol, ports, *sources)
            when :egress
              sources.push(:protocol => protocol, :ports => ports)
              @security_group.revoke_egress(*sources)
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
              authorize(protocol, port_range, *sources)
            end
          end

          def log_id
            vpc = @security_group.vpc_id || :classic
            name = @security_group.name

            unless @options.ec2.own?(@security_group.owner_id)
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

                unless group =~ /\Asg-[0-9a-f]\Z/
                  sg_coll = @options.ec2.security_groups.filter('group-name', group)
                  sg_coll = sg_coll.filter('vpc-id', @security_group.vpc_id) if @security_group.vpc?
                  sg_coll = sg_coll.filter('owner-id', owner_id) unless @options.ec2.own?(owner_id)

                  unless (sg = sg_coll.first)
                    raise "Can't find SecurityGroup: #{owner_id}/#{group} in #{@security_group.vpc_id || :classic}"
                  end

                  group = sg.id
                end

                normalized << {:user_id => owner_id, :group_id => group}
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

          class Permission ###########################################
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
