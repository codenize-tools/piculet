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
ec2 TEST_VPC_ID do
  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
    }
  end

  context 'empty' do #################################################
    it do
      exported = export_security_groups
      expect(exported.keys).to eq([TEST_VPC_ID])

      expect(exported[TEST_VPC_ID]).to eq([[
        [:description , "default VPC security group"],
        [:egress      , EMPTY_ARRAY],
        [:ingress     , EMPTY_ARRAY],
        [:name        , "default"],
        [:owner_id    , TEST_OWNER_ID],
      ]])
    end # it
  end # context ######################################################
end # default
