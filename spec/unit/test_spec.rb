require 'spec_helper'

RSpec.describe 'Test' do
  it 'should get canonical fixnum' do
    result = FormAnswer.canonical_json_numeric(10)
    expect(result).to eq '10'
  end

  it 'should get canonical float' do
    result = FormAnswer.canonical_json_numeric(10.5)
    expect(result).to eq '0.65625E4'
  end
end
