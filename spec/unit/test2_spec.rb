require 'spec_helper'

RSpec.describe 'Test2' do
  it 'should2 get canonical fixnum' do
    result = FormAnswer.canonical_json_numeric(10)
    expect(result).to eq '10'
  end

  it 'should2 get canonical float' do
    result = FormAnswer.canonical_json_numeric(10.5)
    expect(result).to eq '0.65625E4'
  end
end
