require 'piculet/ext/ip-permission-collection-ext'

module Piculet
  class Exporter
    class << self
      def export(ec2, options = {})
        self.new(ec2, options).export
      end
    end # of class methods

    def initialize(ec2, options = {})
      @ec2 = ec2
      @sg_names = options[:sg_names]
    end

    def export
      result = {}
      sgs = @ec2.security_groups
      sgs = @sg_names.map {|i| sgs[i] } if @sg_names

      sgs.each do |sg|
        vpc = sg.vpc
        vpc = vpc.id if vpc
        result[vpc] ||= {}
        result[vpc][sg.id] = export_security_group(sg)
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
      ip_permissions = ip_permissions ? ip_permissions.aggregate : []

      ip_permissions.map do |ip_perm|
        {
          :protocol   => ip_perm.protocol,
          :port_range => ip_perm.port_range,
          :ip_ranges  => ip_perm.ip_ranges,
          :groups => ip_perm.groups.map {|group|
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
