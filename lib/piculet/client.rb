require 'aws-sdk'
require 'piculet/dsl'
require 'piculet/exporter'
require 'piculet/ec2-owner-id-ext'

module Piculet
  class Client
    def initialize(options = {})
      @options = OpenStruct.new(options)
      @options.ec2 = AWS::EC2.new
    end

    def export
      exported = AWS.memoize { Exporter.export(@options.ec2) }
      DSL.convert(exported, @options.ec2.owner_id)
    end
  end # Client
end # Piculet
