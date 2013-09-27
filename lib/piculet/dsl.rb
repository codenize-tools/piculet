require 'ostruct'
require 'piculet/dsl/ec2'
require 'piculet/dsl/converter'

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
  end # DSL
end # Piculet
