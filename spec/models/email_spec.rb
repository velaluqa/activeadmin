RSpec.describe Email do
  describe '::ensure_throttling_delay' do
    describe 'given a numeric' do
      it 'returns this numeric' do
        expect(Email.ensure_throttling_delay(60 * 60)).to eq 60 * 60
      end
    end

    describe 'given recurring string' do
      it 'returns numeric accordingly from Email::THROTTLING_DELAYS' do
        expect(Email.ensure_throttling_delay('hourly')).to eq 60 * 60
        Email::THROTTLING_DELAYS['foo'] = 5
        expect(Email.ensure_throttling_delay('foo')).to eq 5
        Email::THROTTLING_DELAYS.delete('foo')
        expect(Email.ensure_throttling_delay('foo')).to be_nil
      end
    end
  end
end
