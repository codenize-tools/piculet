# Piculet

Piculet is a tool to manage Security Group.

It defines the state of Security Group using DSL, and updates Security Group according to DSL.

## Installation

Add this line to your application's Gemfile:

    gem 'piculet'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install piculet

## Usage

```
shell> export AWS_ACCESS_KEY_ID='...'
shell> export AWS_SECRET_ACCESS_KEY='...'
shell> export AWS_REGION='ap-northeast-1'
shell> #export AWS_OWNER_ID='123456789012'
shell> piculet -e -o Groupfile
shell> vi Groupfile
shell> piculet -a --dry-run
shell> piculet -a
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
