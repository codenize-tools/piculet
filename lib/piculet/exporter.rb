module Piculet
  class Exporter
    class << self
      def export(ec2)
        self.new(ec2).export
      end
    end # of class methods

    def initialize(ec2)
      @ec2 = ec2
    end

    def export
      result = {}

      @ec2.security_groups.each do |security_group|
        vpc = security_group.vpc
        vpc = vpc.id if vpc
        result[vpc] ||= {}
        result[vpc][security_group.id] = export_security_group(security_group)
      end

      return result
    end

    private
    def export_security_group(security_group)
      {
        :name        => security_group.name,
        :description => security_group.description,
        :owner_id    => security_group.owner_id,
        :ingress     => export_ip_permissions(security_group.ingress_ip_permissions),
        :egress      => export_ip_permissions(security_group.egress_ip_permissions),
      }
    end

    def export_ip_permissions(ip_permissions)
      ip_permissions.map do |ip_permission|
        {
          :protocol   => ip_permission.protocol,
          :port_range => ip_permission.port_range,
          :ip_ranges  => ip_permission.ip_ranges,
          :groups => ip_permission.groups.map {|group|
            {
              :id       => group.id,
              :name     => group.name,
              :owner_id => group.owner_id,
            }
          },
        }
      end
    end
  end # Exporter
end # Piculet
