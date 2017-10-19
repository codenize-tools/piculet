module Piculet
  class Exporter
    class << self
      def export(ec2, options = {})
        self.new(ec2, options).export
      end
    end # of class methods

    def initialize(ec2, options = {})
      @ec2 = ec2
      @options = options
    end

    def export
      result = {}
      ec2s = @options[:ec2s]
      sg_names = @options[:sg_names]
      sgs = @ec2.security_groups
      sgs = sgs.select { |sg| sg_names.include?(sg.group_name) } if sg_names
      sgs = sgs.sort_by {|sg| sg.group_name }

      sgs.each do |sg|
        vpc = sg.vpc_id if sg.vpc?

        if ec2s
          next unless ec2s.any? {|i| (i == 'classic' and vpc.nil?) or i == vpc }
        end

        result[vpc] ||= {}
        result[vpc][sg.id] = export_security_group(sg)
      end

      return result
    end

    private
    def export_security_group(security_group)
      {
        :name        => security_group.group_name,
        :description => security_group.description,
        :tags        => tags_to_hash(security_group.tags),
        :owner_id    => security_group.owner_id,
        :ingress     => export_ip_permissions(security_group.ip_permissions),
        :egress      => export_ip_permissions(security_group.ip_permissions_egress),
      }
    end

    def export_ip_permissions(ip_permissions)
      ip_permissions = ip_permissions || []

      ip_permissions = ip_permissions.map do |ip_perm|
        ip_protocol = ip_perm.ip_protocol == "-1" ? :any : ip_perm.ip_protocol.to_sym
        port_range = ip_perm.from_port..ip_perm.to_port
        port_range = nil if port_range == (nil..nil)
        ip_ranges = ip_perm.ip_ranges.map { |range| range.cidr_ip }.sort
        {
          :protocol   => ip_protocol,
          :port_range => port_range,
          :ip_ranges  => ip_ranges,
          :groups => ip_perm.user_id_group_pairs.map {|group|
            group = @ec2.security_groups.find { |g| g.id == group.group_id }
            {
              :id       => group.group_id,
              :name     => group.group_name,
              :owner_id => group.owner_id,
            }
          }.sort_by {|g| g[:name] },
        }
      end

      ip_permissions.sort_by do |ip_perm|
        port_range = ip_perm[:port_range] || (0..0)
        [ip_perm[:protocol], port_range.first, port_range.last]
      end
    end

    def tags_to_hash(tags)
      h = {}
      tags.each {|tag| h[tag.key] = tag.value }
      h
    end
  end # Exporter
end # Piculet
