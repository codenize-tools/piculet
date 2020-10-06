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

  context 'no change' do #################################
    before do
      groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"

    tags(
      "key1" => "value1",
      "key2" => "value2",
    )

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
  security_group "any_other_security_group" do
    description "any other security group"

    tags(
      "key1" => "value1",
      "key2" => "value2",
    )

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
        [:tags        , {"key1"=>"value1", "key2"=>"value2"}],
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

  context 'add' do #################################
    before do
      groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"

    tags(
      "key1" => "value1",
      "key2" => "value2",
    )

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
  security_group "any_other_security_group" do
    description "any other security group"

    tags(
      "key1" => "value1",
      "key2" => "value2",
      "key3" => "value3",
    )

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
        [:tags        , {"key1"=>"value1", "key2"=>"value2", "key3"=>"value3"}],
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

  context 'delete' do #################################
    before do
      groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"

    tags(
      "key1" => "value1",
      "key2" => "value2",
    )

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
  security_group "any_other_security_group" do
    description "any other security group"

    tags(
      "key1" => "value1",
    )

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
        [:tags        , {"key1"=>"value1"}],
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

  context 'update key' do #################################
    before do
      groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"

    tags(
      "key1" => "value1",
      "key2" => "value2",
    )

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
  security_group "any_other_security_group" do
    description "any other security group"

    tags(
      "key1" => "value1",
      "key22" => "value2",
    )

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
        [:tags        , {"key1"=>"value1", "key22"=>"value2"}],
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

  context 'update value' do #################################
    before do
      groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"

    tags(
      "key1" => "value1",
      "key2" => "value2",
    )

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
  security_group "any_other_security_group" do
    description "any other security group"

    tags(
      "key1" => "value1",
      "key2" => "value22",
    )

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
        [:tags        , {"key1"=>"value1", "key2"=>"value22"}],
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
