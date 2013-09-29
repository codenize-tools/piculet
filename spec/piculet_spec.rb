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

  [:ingress, :egress].each do |direction|
    [:tcp, :udp].each do |protocol|
      context "add #{protocol} #{direction} permission allow from ip ranges" do #
        it do
          groupfile { (<<"EOS")
ec2 TEST_VPC_ID do
  security_group "default" do
    description "default VPC security group"

    #{direction} do
      permission #{protocol.inspect}, 80..80 do
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

          expected_permissions = [[
            [:groups     , EMPTY_ARRAY],
            [:ip_ranges  , ["0.0.0.0/0", "127.0.0.1/32"]],
            [:port_range , 80..80],
            [:protocol   , protocol],
          ]]

          case direction
          when :ingress
            egress_value = EMPTY_ARRAY
            ingress_value = expected_permissions
          when :egress
            egress_value = expected_permissions
            ingress_value = EMPTY_ARRAY
          else
            raise 'must not happen'
          end

          exported = export_security_groups
          expect(exported.keys).to eq([TEST_VPC_ID])

          expect(exported[TEST_VPC_ID]).to eq([[
            [:description , "default VPC security group"],
            [:egress      , egress_value],
            [:ingress     , ingress_value],
            [:name        , "default"],
            [:owner_id    , TEST_OWNER_ID],
          ]])
        end # it
      end # context ##################################################

      context "add #{protocol} #{direction} permission allow from groups" do #
        it do
          groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"
  end

  security_group "default" do
    description "default VPC security group"

    #{direction} do
      permission #{protocol.inspect}, 80..80 do
        groups(
          "default",
          "any_other_security_group"
        )
      end # permission
    end # ingress
  end # security_group
end # ec2
EOS
          }

          expected_permissions = [[
            [:groups     , [
              [[:name, "any_other_security_group"], [:owner_id, TEST_OWNER_ID]],
              [[:name, "default"]                 , [:owner_id, TEST_OWNER_ID]],
            ]],
            [:ip_ranges  , EMPTY_ARRAY],
            [:port_range , 80..80],
            [:protocol   , protocol],
          ]]

          case direction
          when :ingress
            egress_value = EMPTY_ARRAY
            ingress_value = expected_permissions
          when :egress
            egress_value = expected_permissions
            ingress_value = EMPTY_ARRAY
          else
            raise 'must not happen'
          end

          exported = export_security_groups
          expect(exported.keys).to eq([TEST_VPC_ID])

          expect(exported[TEST_VPC_ID]).to eq([[
            [:description , "any other security group"],
            [:egress      , EMPTY_ARRAY],
            [:ingress     , EMPTY_ARRAY],
            [:name        , "any_other_security_group"],
            [:owner_id    , TEST_OWNER_ID],
          ],[
            [:description , "default VPC security group"],
            [:egress      , egress_value],
            [:ingress     , ingress_value],
            [:name        , "default"],
            [:owner_id    , TEST_OWNER_ID],
          ]])
        end # it
      end # context ##################################################

      context "add #{protocol} #{direction} permission allow from ip ranges and groups" do #
        it do
          groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"
  end

  security_group "default" do
    description "default VPC security group"

    #{direction} do
      permission #{protocol.inspect}, 80..80 do
        ip_ranges(
          "0.0.0.0/0",
          "127.0.0.1/32"
        )
        groups(
          "default",
          "any_other_security_group"
        )
      end # permission
    end # ingress
  end # security_group
end # ec2
EOS
          }

          expected_permissions = [[
            [:groups     , [
              [[:name, "any_other_security_group"], [:owner_id, TEST_OWNER_ID]],
              [[:name, "default"]                 , [:owner_id, TEST_OWNER_ID]],
            ]],
            [:ip_ranges  , ["0.0.0.0/0", "127.0.0.1/32"]],
            [:port_range , 80..80],
            [:protocol   , protocol],
          ]]

          case direction
          when :ingress
            egress_value = EMPTY_ARRAY
            ingress_value = expected_permissions
          when :egress
            egress_value = expected_permissions
            ingress_value = EMPTY_ARRAY
          else
            raise 'must not happen'
          end

          exported = export_security_groups
          expect(exported.keys).to eq([TEST_VPC_ID])

          expect(exported[TEST_VPC_ID]).to eq([[
            [:description , "any other security group"],
            [:egress      , EMPTY_ARRAY],
            [:ingress     , EMPTY_ARRAY],
            [:name        , "any_other_security_group"],
            [:owner_id    , TEST_OWNER_ID],
          ],[
            [:description , "default VPC security group"],
            [:egress      , egress_value],
            [:ingress     , ingress_value],
            [:name        , "default"],
            [:owner_id    , TEST_OWNER_ID],
          ]])
        end # it
      end # context ##################################################
    end # each #######################################################
  end # each #########################################################
end # default
