# Piculet

Piculet is a tool to manage EC2 Security Group.

It defines the state of EC2 Security Group using DSL, and updates EC2 Security Group according to DSL.

[![Build Status](https://drone.io/bitbucket.org/winebarrel/piculet/status.png)](https://drone.io/bitbucket.org/winebarrel/piculet/latest)

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
piculet -e -o Groupfile
vi Groupfile
piculet -a --dry-run
piculet -a
```

## Groupfile example

```ruby
require 'other/groupfile'

ec2 do
  security_group "default" do
    description "default group"

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

## Link
* [RubyGems.org site](http://rubygems.org/gems/piculet)
