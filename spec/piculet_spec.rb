$: << File.expand_path("#{File.dirname __FILE__}/../lib")
$: << File.expand_path("#{File.dirname __FILE__}/../spec")

require 'rubygems'
require 'piculet'
require 'spec_helper'

describe Piculet::Client do
  before(:each) {
    #groupfile(:force => true) { '' }
  }

  after(:all) do
    #groupfile(:force => true) { '' }
  end

  context 'XXX' do
    it  {
      expect(1).to eq(1)
    }
  end
end
