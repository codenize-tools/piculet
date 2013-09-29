require 'aws-sdk'

TEST_VPC_ID = ENV['TEST_VPC_ID']
TEST_OWNER_ID = ENV['TEST_OWNER_ID']
RETRY_TIMES = 256

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

    RETRY_TIMES.times do
      updated = client.apply(tempfile) rescue nil
      break unless updated.nil?
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

  client = Piculet::Client.new(options)
  client.export {|exported, converter| exported }
end

def list_security_groups(security_groups)
  security_groups.map {|k, v| v }.sort_by {|i| i[:name] }
end
