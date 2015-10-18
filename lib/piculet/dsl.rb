module Piculet
  class DSL
    include Piculet::TemplateHelper

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
      @result = OpenStruct.new(:ec2s => {})

      @context = Hashie::Mash.new(
        :path => path,
        :templates => {}
      )

      instance_eval(&block)
    end

    private

    def template(name, &block)
      @context.templates[name.to_s] = block
    end

    def require(file)
      groupfile = (file =~ %r|\A/|) ? file : File.expand_path(File.join(File.dirname(@path), file))

      if File.exist?(groupfile)
        instance_eval(File.read(groupfile), groupfile)
      elsif File.exist?(groupfile + '.rb')
        instance_eval(File.read(groupfile + '.rb'), groupfile + '.rb')
      else
        Kernel.require(file)
      end
    end

    def ec2(vpc = nil, &block)
      if (ec2_result = @result.ec2s[vpc])
        @result.ec2s[vpc] = EC2.new(@context, vpc, ec2_result.security_groups, &block).result
      else
        @result.ec2s[vpc] = EC2.new(@context, vpc, [], &block).result
      end
    end
  end # DSL
end # Piculet
