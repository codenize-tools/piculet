$: << File.expand_path("#{File.dirname __FILE__}/../lib")
$: << File.expand_path("#{File.dirname __FILE__}/../spec")

require 'rubygems'
require 'piculet'
require 'spec_helper'

describe Piculet::Client do
  before(:each) {
    groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
    }

    @ec2 = AWS::EC2.new
  }

  after(:all) do
    groupfile { (<<-EOS)
ec2 "vpc-4f803c27" do
  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
    }
  end

  context 'empty' do
    it do
      exported = export_security_groups
      expect(exported.keys).to eq([TEST_VPC_ID])

      sg_list = list_security_groups(exported[TEST_VPC_ID])
      expect(sg_list).to eq([{
        :name        => "default",
        :description => "default VPC security group",
        :owner_id    => TEST_OWNER_ID,
        :ingress     => [],
        :egress      => []
      }])
    end # it
  end # context

  context 'add ingress tcp permission allow from ip ranges' do
    it do
      groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "default" do
    description "default VPC security group"

    ingress do
      permission :tcp, 80..80 do
        ip_ranges(
          "0.0.0.0/0",
          "127.0.0.1/32"
        )
      end # permission
    end # ingress
  end # security_group
end # ec2
EOS
      }

      exported = export_security_groups
      expect(exported.keys).to eq([TEST_VPC_ID])

      sg_list = list_security_groups(exported[TEST_VPC_ID])
      expect(sg_list).to eq([{
        :name        => "default",
        :description => "default VPC security group",
        :owner_id    => TEST_OWNER_ID,
        :egress      => [],
        :ingress => [{
          :protocol=>:tcp,
          :port_range=>80..80,
          :ip_ranges=>["0.0.0.0/0", "127.0.0.1/32"],
          :groups=>[]
        }],
      }])
    end # it
  end # context
end # default
