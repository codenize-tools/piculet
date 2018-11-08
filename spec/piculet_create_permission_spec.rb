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

  [:ingress, :egress].each do |direction|
    [[:tcp, 80..81], [:udp, 53..54], [:any, nil], [:icmp, -1..-1], [:"50", nil], [:tcp, 80]].each do |protocol, port_range|
      context "add #{protocol} #{direction} permission allow from ip ranges" do #
        it do
          groupfile { (<<"EOS")
ec2 TEST_VPC_ID do
  security_group "default" do
    description "default VPC security group"

    #{direction} do
      permission #{protocol.inspect}, #{port_range.inspect} do
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
            [:port_range , port_range.kind_of?(Integer) ? port_range..port_range : port_range],
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
            [:tags        , {}],
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
      permission #{protocol.inspect}, #{port_range.inspect} do
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
            [:port_range , port_range.kind_of?(Integer) ? port_range..port_range : port_range],
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
            [:tags        , {}],
          ],[
            [:description , "default VPC security group"],
            [:egress      , egress_value],
            [:ingress     , ingress_value],
            [:name        , "default"],
            [:owner_id    , TEST_OWNER_ID],
            [:tags        , {}],
          ]])
        end # it
      end # context ##################################################

      context "add #{protocol} #{direction} permission allow from groups (using security groups id)" do #
        before do
          groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"
  end

  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
          }
        end

        it do
          any_other_security_group_id = export_security_groups(:include_security_group_id => true)[TEST_VPC_ID][0][0]

          groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"
  end

  security_group "default" do
    description "default VPC security group"

    #{direction} do
      permission #{protocol.inspect}, #{port_range.inspect} do
        groups(
          "default",
          "#{any_other_security_group_id}"
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
            [:port_range , port_range.kind_of?(Integer) ? port_range..port_range : port_range],
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
            [:tags        , {}],
          ],[
            [:description , "default VPC security group"],
            [:egress      , egress_value],
            [:ingress     , ingress_value],
            [:name        , "default"],
            [:owner_id    , TEST_OWNER_ID],
            [:tags        , {}],
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
      permission #{protocol.inspect}, #{port_range.inspect} do
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
            [:port_range , port_range.kind_of?(Integer) ? port_range..port_range : port_range],
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
            [:tags        , {}],
          ],[
            [:description , "default VPC security group"],
            [:egress      , egress_value],
            [:ingress     , ingress_value],
            [:name        , "default"],
            [:owner_id    , TEST_OWNER_ID],
            [:tags        , {}],
          ]])
        end # it
      end # context ##################################################
    end # each #######################################################

    context "add cross-reference #{direction} permission" do ######################
      before do
        groupfile { (<<EOS)
ec2 TEST_VPC_ID do
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
  security_group "security_group_a" do
    description "security group A"

    #{direction} do
      permission :tcp, 80..80 do
        groups(
          "security_group_b",
        )
      end # permission
    end # ingress
  end

  security_group "security_group_b" do
    description "security group B"

    #{direction} do
      permission :tcp, 80..80 do
        groups(
          "security_group_a",
        )
      end # permission
    end # ingress
  end

  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
        }

        expected_permissions = proc do |sg_name|
          [[
            [:groups     , [
              [[:name, sg_name], [:owner_id, TEST_OWNER_ID]],
            ]],
            [:ip_ranges  , EMPTY_ARRAY],
            [:port_range , 80..80],
            [:protocol   , :tcp],
          ]]
        end

        case direction
        when :ingress
          egress_value = proc {|i| EMPTY_ARRAY }
          ingress_value = expected_permissions
        when :egress
          egress_value = expected_permissions
          ingress_value = proc {|i| EMPTY_ARRAY }
        else
          raise 'must not happen'
        end

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
          [:description , "security group A"],
          [:egress      , egress_value.call('security_group_b')],
          [:ingress     , ingress_value.call('security_group_b')],
          [:name        , "security_group_a"],
          [:owner_id    , TEST_OWNER_ID],
          [:tags        , {}],
        ],[
          [:description , "security group B"],
          [:egress      , egress_value.call('security_group_a')],
          [:ingress     , ingress_value.call('security_group_a')],
          [:name        , "security_group_b"],
          [:owner_id    , TEST_OWNER_ID],
          [:tags        , {}],
        ]])
      end # it
    end # context ##################################################
  end # each #########################################################
end # describe
