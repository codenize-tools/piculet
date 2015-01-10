# Piculet

Piculet is a tool to manage EC2 Security Group.

It defines the state of EC2 Security Group using DSL, and updates EC2 Security Group according to DSL.

[![Gem Version](https://badge.fury.io/rb/piculet.png)](http://badge.fury.io/rb/piculet)
[![Build Status](https://travis-ci.org/winebarrel/piculet.svg?branch=master)](https://travis-ci.org/winebarrel/piculet)

## Installation

Add this line to your application's Gemfile:

    gem 'piculet'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install piculet

## Usage

```sh
export AWS_ACCESS_KEY_ID='...'
export AWS_SECRET_ACCESS_KEY='...'
export AWS_REGION='ap-northeast-1'
#export AWS_OWNER_ID='123456789012'
# Note: If you do not set the OWNER_ID,
#       Piculet get the OWNER_ID from GetUser(IAM) or CreateSecurityGroup(EC2)
piculet -e -o Groupfile  # export EC2 SecurityGroup
vi Groupfile
piculet -a --dry-run
piculet -a               # apply `Groupfile` to EC2 SecurityGroup
```

## Help
```
Usage: piculet [options]
    -p, --profile PROFILE_NAME
        --credentials-path PATH
    -k, --access-key ACCESS_KEY
    -s, --secret-key SECRET_KEY
    -r, --region REGION
    -a, --apply
    -f, --file FILE
    -n, --names SG_LIST
    -x, --exclude SG_LIST
        --ec2s VPC_IDS
        --dry-run
    -e, --export
    -o, --output FILE
        --split
        --no-color
        --debug
```

## Groupfile example

```ruby
require 'other/groupfile'

ec2 do
  security_group "default" do
    description "default group for EC2 Classic"

    tags(
      "key1" => "value1",
      "key2" => "value2"
    )

    ingress do
      permission :tcp, 0..65535 do
        groups(
          "default"
        )
      end
      permission :udp, 0..65535 do
        groups(
          "default"
        )
      end
      permission :icmp, -1..-1 do
        groups(
          "default"
        )
      end
      permission :tcp, 22..22 do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
      permission :udp, 60000..61000 do
        ip_ranges(
          "0.0.0.0/0",
        )
      end
    end
  end
end

ec2 "vpc-XXXXXXXX" do
  security_group "default" do
    description "default VPC security group"

    tags(
      "key1" => "value1",
      "key2" => "value2"
    )

    ingress do
      permission :tcp, 22..22 do
        ip_ranges(
          "0.0.0.0/0",
        )
      end
      permission :tcp, 80..80 do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
      permission :udp, 60000..61000 do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
      # ESP (IP Protocol number: 50)
      permission :"50" do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
      permission :any do
        groups(
          "any_other_group",
          "default"
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

  security_group "any_other_group" do
    description "any_other_group"

    tags(
      "key1" => "value1",
      "key2" => "value2"
    )

    egress do
      permission :any do
        ip_ranges(
          "0.0.0.0/0"
        )
      end
    end
  end
end
```

## Similar tools
* [Codenize.tools](http://codenize.tools/)
