describe 'v1/visits/index' do
  let(:study) { create(:study) }
  let(:center) { create(:center, study: study) }
  let(:patient) { create(:patient, center: center) }

  it 'displays all the visits' do
    assign(
      :visits,
      [
        create(:visit, patient: patient),
        create(:visit, patient: patient)
      ]
    )

    render

    expect(rendered).to match /"state":"incomplete_na"/
  end
end
