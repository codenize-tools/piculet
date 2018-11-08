module Piculet
  class DSL
    class Converter
      class << self
        def convert(exported, owner_id)
          self.new(exported, owner_id).convert
        end
      end # of class methods

      def initialize(exported, owner_id)
        @exported = exported
        @owner_id = owner_id
      end

      def convert
        @exported.each.map {|vpc, security_groups|
          output_ec2(vpc, security_groups)
        }.join("\n")
      end

      private
      def output_ec2(vpc, security_groups)
        vpc = vpc ? vpc.to_s.inspect + ' ' : ''
        security_groups = security_groups.map {|sg_id, sg|
          output_security_group(sg_id, sg)
        }.join("\n").strip

        <<-EOS
ec2 #{vpc}do
  #{security_groups}
end
        EOS
      end

      def output_security_group(security_group_id, security_group)
        name = security_group[:name].inspect
        description = security_group[:description].inspect
        tags = ''

        unless security_group[:tags].empty?
          tags = "\n\n    tags(\n      " +
                 security_group[:tags].map {|k, v|
                   k.inspect + ' => ' + v.inspect
                 }.join(",\n      ") +
                 "\n    )"
        end

        ingress = security_group.fetch(:ingress, [])
        egress = security_group.fetch(:egress, [])

        ingress_egress = [
          output_permissions(:ingress, ingress),
          output_permissions(:egress, egress),
        ].select {|i| i }

        ingress_egress = ingress_egress.empty? ? '' : "\n\n    " + ingress_egress.join("\n").strip

        <<-EOS
  security_group #{name} do
    description #{description}#{
    tags}#{
    ingress_egress}
  end
        EOS
      end

      def output_permissions(direction, permissions)
        return nil if permissions.empty?
        permissions = permissions.map {|i| output_perm(i) }.join.strip

        <<-EOS
    #{direction} do
      #{permissions}
    end
        EOS
      end

      def output_perm(permission)
        protocol = permission[:protocol].to_sym
        port_range = permission[:port_range]
        port_range = eval(port_range) if port_range.kind_of?(String)
        args = [protocol, port_range].select {|i| i }.map {|i| i.inspect }.join(', ') + ' '

        ip_ranges = permission.fetch(:ip_ranges, [])
        groups = permission.fetch(:groups, [])

        ip_ranges_groups = [
          output_ip_ranges(ip_ranges),
          output_groups(groups),
        ].select {|i| i }.join.strip

        ip_ranges_groups.insert(0, "\n        ") unless ip_ranges_groups.empty?

        <<-EOS
      permission #{args}do#{
        ip_ranges_groups}
      end
        EOS
      end

      def output_ip_ranges(ip_ranges)
        return nil if ip_ranges.empty?
        ip_ranges = ip_ranges.map {|i| i.inspect }.join(",\n          ")

        <<-EOS
        ip_ranges(
          #{ip_ranges}
        )
        EOS
      end

      def output_groups(groups)
        return nil if groups.empty?

        groups = groups.map {|i|
          name_or_id = i[:name] || i[:id]
          owner_id = i[:owner_id]

          if Aws::EC2::SecurityGroup.elb?(owner_id)
            arg = Aws::EC2::SecurityGroup.elb_sg
          elsif @owner_id == owner_id
            arg = name_or_id
          else
            arg = [owner_id, i[:id]]
          end

          arg.inspect
        }.join(",\n          ")

        <<-EOS
        groups(
          #{groups}
        )
        EOS
      end
    end # Converter
  end # DSL
end # Piculet
