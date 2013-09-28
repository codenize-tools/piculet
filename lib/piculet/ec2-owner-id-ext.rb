require 'aws-sdk'

module AWS
  class EC2
    DESC_OWNER_ID_RETRY_TIMES   = 3
    DESC_OWNER_ID_RETRY_WAIT    = 0.3
    SECURITY_GROUP_NAME_MAX_LEN = 255

    def owner_id
      return ENV['AWS_OWNER_ID'] if ENV['AWS_OWNER_ID']

      unless @owner_id
        security_group = create_random_security_group
        return nil unless security_group
        @owner_id = security_group.owner_id
        delete_random_security_group(security_group)
      end

      return @owner_id
    end

    private
    def create_random_security_group
      security_group = nil

      DESC_OWNER_ID_RETRY_TIMES.times do
        name = random_security_group_name
        security_group = self.security_groups.create(name) rescue nil
        break if security_group
      end

      return security_group
    end

    def delete_random_security_group(security_group)
      exception = nil

      DESC_OWNER_ID_RETRY_TIMES.times do
        begin
          security_group.delete
          break
        rescue => e
          exception = e
        end
      end

      raise exception if exception
    end

    def random_security_group_name
      name = []
      len = SECURITY_GROUP_NAME_MAX_LEN

      while name.length < len
        name.concat(('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a)
      end

      name.shuffle[0...len].join
    end
  end # EC2
end # AWS
