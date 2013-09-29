$: << File.expand_path("#{File.dirname __FILE__}/../lib")
$: << File.expand_path("#{File.dirname __FILE__}/../spec")

require 'rubygems'
require 'piculet'
require 'spec_helper'

describe Piculet::Client do
  before(:each) {
    groupfile { (<<-EOS)
ec2 TEST_VPC_ID do
  security_group "default" do
    description "default VPC security group"
  end
end
      EOS
    }

    @ec2 = AWS::EC2.new
  }

  after(:all) do
    groupfile { (<<-EOS)
ec2 "vpc-4f803c27" do
  security_group "default" do
    description "default VPC security group"
  end
end
      EOS
    }
  end

  context 'empty' do
    it  {
      exported = export_security_groups
      expect(exported.keys).to eq([TEST_VPC_ID])

      sg_list = list_security_groups(exported[TEST_VPC_ID])
      expect(sg_list).to eq([
        {:name => "default", :description => "default VPC security group", :owner_id => TEST_OWNER_ID, :ingress => [], :egress => []},
      ])
    }
  end
end
