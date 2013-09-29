require 'aws-sdk'

TEST_VPC_ID = ENV['TEST_VPC_ID']
TEST_OWNER_ID = ENV['TEST_OWNER_ID']
RETRY_TIMES = 10
EMPTY_ARRAY = []

AWS.config({
  :access_key_id => (ENV['TEST_AWS_ACCESS_KEY_ID'] || 'scott'),
  :secret_access_key => (ENV['TEST_AWS_SECRET_ACCESS_KEY'] || 'tiger'),
  :region => ENV['TEST_AWS_REGION'],
})

def groupfile(options = {})
  updated = false
  tempfile = `mktemp /tmp/#{File.basename(__FILE__)}.XXXXXX`.strip

  begin
    open(tempfile, 'wb') {|f| f.puts(yield) }
    options = {:logger => Logger.new('/dev/null')}.merge(options)

    if options[:debug]
      AWS.config({
        :http_wire_trace => true,
        :logger => (options[:logger] || Piculet::Logger.instance),
      })
    end

    client = Piculet::Client.new(options)

    (1..RETRY_TIMES).each do |i|
      begin
        updated = client.apply(tempfile)
        break
      rescue AWS::EC2::Errors::InvalidGroup::NotFound => e
        raise e unless i < RETRY_TIMES
      end
    end
  ensure
    FileUtils.rm_f(tempfile)
  end

  return updated
end

def export_security_groups(options = {})
  options = {:logger => Logger.new('/dev/null')}.merge(options)

  if options[:debug]
    AWS.config({
      :http_wire_trace => true,
      :logger => (options[:logger] || Piculet::Logger.instance),
    })
  end

  sleep ENV['TEST_EXPORT_DELAY'].to_f

  client = Piculet::Client.new(options)
  exported = client.export {|e, c| e }

  exported.keys.each do |vpc|
    security_groups = exported[vpc]

    security_groups.each do |sg_id, sg|
      [:ingress, :egress].each do |direction|
        if (perm_list = sg[direction])
          perm_list.each do |perm|
            if (ip_ranges = perm[:ip_ranges])
              perm[:ip_ranges] = ip_ranges.sort
            end

            if (groups = perm[:groups])
              groups.each {|g| g.delete(:id) }
              perm[:groups] = groups.sort_by {|g| g[:name] }.map {|g| g.sort_by {|k, v| k } }
            end
          end

          sg[direction] = perm_list.map {|perm| perm.sort_by {|k, v| k } }
        end
      end
    end

    exported[vpc] = security_groups.sort_by {|sg_id, sg| sg[:name] }.map {|sg_id, sg| sg.sort_by {|k, v| k } }
  end

  return exported
end
