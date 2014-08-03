module AWS
  class EC2
    class SecurityGroup
      DESC_SECURITY_GROUP_RETRY_TIMES = 3
      DESC_SECURITY_GROUP_RETRY_WAIT  = 3

      class IpPermissionCollection
        def aggregate
          aggregated = nil

          (1..DESC_SECURITY_GROUP_RETRY_TIMES).each do |i|
            begin
              aggregated = {}

              self.each do |perm|
                key = [perm.protocol, perm.port_range]
                aggregated[key] ||= {:ip_ranges => [], :groups => []}
                aggregated[key][:ip_ranges].concat(perm.ip_ranges || [])
                aggregated[key][:groups].concat(perm.groups || [])
              end

              break
            rescue AWS::EC2::Errors::InvalidGroup::NotFound => e
              raise e unless i < DESC_SECURITY_GROUP_RETRY_TIMES
              sleep DESC_SECURITY_GROUP_RETRY_WAIT
            end
          end

          aggregated.map do |key, attrs|
            protocol, port_range = key

            OpenStruct.new({
              :protocol   => protocol,
              :port_range => port_range,
            }.merge(attrs))
          end
        end
      end # IpPermissionCollection
    end # SecurityGroup
  end # EC2
end # AWS
