require "canonical_json"

describe(Object) do
  let(:array) do
    [
      '1',
      true,
      false,
      1.333333333333333,
      nil,
      {
        b: "2",
        a: "1"
      }
    ]
  end

  let(:hash) do
    {
      "001": '1',
      "1": true,
      "c": false,
      "a": 1.333333333333333,
      "aa": nil,
      2 => {
        b: "2",
        a: "1"
      }
    }
  end

  it "generates canonical json from arrays" do
    expected_json = "[\"1\",true,false,0.6666666666667E1,null,{\"a\":\"1\",\"b\":\"2\"}]"
    expect(array.to_canonical_json).to eq(expected_json)
  end
  
  it "generates canonical json from hash objects" do
    expected_json = "{\"001\":\"1\",\"1\":true,\"2\":{\"a\":\"1\",\"b\":\"2\"},\"a\":0.6666666666667E1,\"aa\":null,\"c\":false}"
    expect(hash.to_canonical_json).to eq(expected_json)
  end
end
