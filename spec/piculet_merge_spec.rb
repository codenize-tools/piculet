describe Piculet::Client do
  before(:each) {
    groupfile { (<<-RUBY)
ec2 TEST_VPC_ID do
  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
RUBY
    }

    @ec2 = Aws::EC2::Resource.new
  }

  after(:all) do
    groupfile { (<<-RUBY)
ec2 TEST_VPC_ID do
  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
RUBY
    }
  end

  context 'create security group with splitted permission' do #################################
    let(:dsl) {
      <<-RUBY
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"

    ingress do
      permission :any do
        ip_ranges(
          "0.0.0.0/0"
        )
      end

      permission :any do
        ip_ranges(
          "127.0.0.1/32"
        )
      end
    end

    egress do
      permission :any do
        ip_ranges(
          "0.0.0.0/0"
        )
      end

      permission :any do
        ip_ranges(
          "127.0.0.2/32"
        )
      end
    end
  end

  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
      RUBY
    }

    it do
      groupfile(:merge_definition => true) { dsl }

      exported = export_security_groups
      expect(exported.keys).to eq([TEST_VPC_ID])

      expect(exported[TEST_VPC_ID]).to eq([[
        [:description , "any other security group"],
        [:egress      , [[
          [:groups     , EMPTY_ARRAY],
          [:ip_ranges  , ["0.0.0.0/0", "127.0.0.2/32"]],
          [:port_range , nil],
          [:protocol   , :any],
        ]]],
        [:ingress     , [[
          [:groups     , EMPTY_ARRAY],
          [:ip_ranges  , ["0.0.0.0/0", "127.0.0.1/32"]],
          [:port_range , nil],
          [:protocol   , :any],
        ]]],
        [:name        , "any_other_security_group"],
        [:owner_id    , TEST_OWNER_ID],
        [:tags        , {}],
      ],[
        [:description , "default VPC security group"],
        [:egress      , EMPTY_ARRAY],
        [:ingress     , EMPTY_ARRAY],
        [:name        , "default"],
        [:owner_id    , TEST_OWNER_ID],
        [:tags        , {}],
      ]])
    end # it
  end # context ######################################################
end # describe
