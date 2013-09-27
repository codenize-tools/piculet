require 'ostruct'
require 'piculet/dsl-converter'

module Piculet
  class DSL
    class << self
      def define(source, path)
        self.new(path) do
          eval(source, binding)
        end
      end

      def convert(exported, owner_id)
        Converter.convert(exported, owner_id)
      end
    end # of class methods

    attr_reader :result

    def initialize(path, &block)
      @path = path
      @result = OpenStruct.new(:ec2s => [])
      instance_eval(&block)
    end

    private
    def require(file)
      groupfile = File.expand_path(File.join(File.dirname(@path), file))

      if File.exist?(groupfile)
        instance_eval(File.read(groupfile))
      elsif File.exist?(groupfile + '.rb')
        instance_eval(File.read(groupfile + '.rb'))
      else
        Kernel.require(file)
      end
    end

    def ec2(vpc = nil, &block)
      @result.ec2s << EC2.new(vpc, &block).result
    end

    class EC2
      attr_reader :result

      def initialize(vpc, &block)
        @result = OpenStruct.new({
          :vpc             => vpc,
          :security_groups => [],
        })

        instance_eval(&block)
      end

      private
      def security_group(name, &block)
        @result.security_groups << SecurityGroup.new(name, &block).result
      end

      class SecurityGroup
        def initialize(name, &block)
          @name = name

          @result = OpenStruct.new({
            :name    => name,
            :ingress => [],
            :egress  => [],
          })

          instance_eval(&block)
        end

        def result
          unless @result.description
            raise "SecurityGroup `#{@name}`: `description` is required"
          end

          @result
        end

        private
        def description(value)
          @result.description = value
        end

        def ingress(&block)
          @result.ingress << Permissions.new(@name, :ingress, &block).result
        end

        def egress(&block)
          @result.egress << Permissions.new(@name, :egress, &block).result
        end

        class Permissions
          attr_reader :result

          def initialize(security_group, direction, &block)
            @security_group = security_group
            @direction = direction
            @result = {}
            instance_eval(&block)
          end

          private
          def permission(protocol, port_range = nil, &block)
            if port_range and not port_range.kind_of?(Range)
              raise TypeError, "SecurityGroup `#{@security_group}`: #{@direction}: can't convert #{port_range} into Range"
            end

            key = [protocol, port_range]

            if @result.has_key?(key)
              raise "SecurityGroup `#{@security_group}`: #{@direction}: #{key} is already defined"
            end

            @result[key] = Permission.new(@security_group, @direction, key, &block).result
          end

          class Permission
            def initialize(security_group, direction, protocol_prot_range, &block)
              @security_group = security_group
              @direction = direction
              @protocol_prot_range = protocol_prot_range
              @result = OpenStruct.new
              instance_eval(&block)
            end

            def result
              unless @result.ip_ranges or @result.groups
                raise "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `ip_ranges` or `groups` is required"
              end

              @result
            end

            private
            def ip_ranges(*values)
              if values.empty?
                raise ArgumentError, "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `ip_ranges`: wrong number of arguments (0 for 1..)"
              end

              values.each do |ip_range|
                unless ip_range =~ %r|\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}|
                  raise "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `ip_ranges`: invalid ip range: #{ip_range}"
                end

                ip, range = ip_range.split('/', 2)

                unless ip.split('.').all? {|i| (0..255).include?(i.to_i) } and (0..32).include?(range.to_i)
                  raise "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `ip_ranges`: invalid ip range: #{ip_range}"
                end
              end

              @result.ip_ranges = values
            end
 
            def groups(*values)
              if values.empty?
                raise ArgumentError, "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `groups`: wrong number of arguments (0 for 1..)"
              end

              values.each do |group|
                unless [String, Array].any? {|i| group.kind_of?(i) }
                  raise "SecurityGroup `#{@security_group}`: #{@direction}: #{@protocol_prot_range}: `groups`: invalid type: #{group}"
                end
              end

              @result.groups = values
            end
          end # Permission
        end # Permissions
      end # SecurityGroup
    end # EC2
  end # DSL
end # Piculet
