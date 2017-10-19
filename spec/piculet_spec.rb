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

    @ec2 = Aws::EC2::Resource.new
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
        [:tags        , {}],
      ]])
    end # it
  end # context ######################################################

  context 'create security group' do #################################
    it do
      groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"

    ingress do
      permission :any do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
    end

    egress do
      permission :any do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
    end
  end

  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
      }

      exported = export_security_groups
      expect(exported.keys).to eq([TEST_VPC_ID])

      expect(exported[TEST_VPC_ID]).to eq([[
        [:description , "any other security group"],
        [:egress      , [[
          [:groups     , EMPTY_ARRAY],
          [:ip_ranges  , ["0.0.0.0/0"]],
          [:port_range , nil],
          [:protocol   , :any],
        ]]],
        [:ingress     , [[
          [:groups     , EMPTY_ARRAY],
          [:ip_ranges  , ["0.0.0.0/0"]],
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

  context 'create security group with template' do ###################
    it do
      groupfile { (<<EOS)
template "basic" do
  ingress do
    permission :any do
      ip_ranges(
        context.ingress_ip_range
      )
    end
  end

  egress do
    permission :any do
      ip_ranges(
        context.egress_ip_range
      )
    end
  end
end

ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"
    context.ingress_ip_range = "0.0.0.0/0"
    include_template "basic", egress_ip_range: "0.0.0.0/0"
  end

  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
      }

      exported = export_security_groups
      expect(exported.keys).to eq([TEST_VPC_ID])

      expect(exported[TEST_VPC_ID]).to eq([[
        [:description , "any other security group"],
        [:egress      , [[
          [:groups     , EMPTY_ARRAY],
          [:ip_ranges  , ["0.0.0.0/0"]],
          [:port_range , nil],
          [:protocol   , :any],
        ]]],
        [:ingress     , [[
          [:groups     , EMPTY_ARRAY],
          [:ip_ranges  , ["0.0.0.0/0"]],
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

  context 'delete security group' do #################################
    before do
      groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"

    ingress do
      permission :any do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
    end

    egress do
      permission :any do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
    end
  end

  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
      }
    end

    it do
      groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
      }

      exported = export_security_groups
      expect(exported.keys).to eq([TEST_VPC_ID])

      expect(exported[TEST_VPC_ID]).to eq([[
        [:description , "default VPC security group"],
        [:egress      , EMPTY_ARRAY],
        [:ingress     , EMPTY_ARRAY],
        [:name        , "default"],
        [:owner_id    , TEST_OWNER_ID],
        [:tags        , {}],
      ]])
    end # it
  end # context ######################################################

  context 'create security group from divided config' do #############
    it do
      groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "security_group_a" do
    description "security group a"

    ingress do
      permission :any do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
    end

    egress do
      permission :any do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
    end
  end

  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2

ec2 TEST_VPC_ID do
  security_group "security_group_b" do
    description "security group b"

    ingress do
      permission :any do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
    end

    egress do
      permission :any do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
    end
  end
end # ec2
EOS
      }

      exported = export_security_groups
      expect(exported.keys).to eq([TEST_VPC_ID])

      expect(exported[TEST_VPC_ID]).to eq([[
        [:description , "default VPC security group"],
        [:egress      , EMPTY_ARRAY],
        [:ingress     , EMPTY_ARRAY],
        [:name        , "default"],
        [:owner_id    , TEST_OWNER_ID],
        [:tags        , {}],
      ],[
        [:description , "security group a"],
        [:egress      , [[
          [:groups     , EMPTY_ARRAY],
          [:ip_ranges  , ["0.0.0.0/0"]],
          [:port_range , nil],
          [:protocol   , :any],
        ]]],
        [:ingress     , [[
          [:groups     , EMPTY_ARRAY],
          [:ip_ranges  , ["0.0.0.0/0"]],
          [:port_range , nil],
          [:protocol   , :any],
        ]]],
        [:name        , "security_group_a"],
        [:owner_id    , TEST_OWNER_ID],
        [:tags        , {}],
      ],[
        [:description , "security group b"],
        [:egress      , [[
          [:groups     , EMPTY_ARRAY],
          [:ip_ranges  , ["0.0.0.0/0"]],
          [:port_range , nil],
          [:protocol   , :any],
        ]]],
        [:ingress     , [[
          [:groups     , EMPTY_ARRAY],
          [:ip_ranges  , ["0.0.0.0/0"]],
          [:port_range , nil],
          [:protocol   , :any],
        ]]],
        [:name        , "security_group_b"],
        [:owner_id    , TEST_OWNER_ID],
        [:tags        , {}],
      ]])
    end # it
  end # context ######################################################
end # describe
