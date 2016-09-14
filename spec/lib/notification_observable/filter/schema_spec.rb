RSpec.describe NotificationObservable::Filter::Schema, focus: true do
  with_model :TestModel do
    table do |t|
      t.string :foo
      t.references :sub_model
    end
    model do
      belongs_to :sub_model
    end
  end

  with_model :SubModel do
    table do |t|
      t.integer :foo
    end
    model do
      has_one :test_model
      has_many :sub_sub_models
    end
  end

  with_model :SubSubModel do
    table do |t|
      t.datetime :foobar, null:false
      t.text :foobaz, null: true
      t.references :sub_model
    end
    model do
      belongs_to :sub_model
    end
  end

  describe '#for_model' do
    before(:each) do
      @schema = NotificationObservable::Filter::Schema.new().for_model(TestModel)
    end

    it 'returns schema for root attributes' do
      expect(@schema).to include(:oneOf)
      expect(@schema[:oneOf]).to include(include(title: 'id'))
      expect(@schema[:oneOf].detect { |x| x[:title] == 'id' })
        .to include(properties: {
                      'id' => {
                        oneOf: [
                          {
                            type: 'object',
                            properties: {
                              matches: {
                                type: 'number'
                              }
                            }
                          },
                          {
                            type: 'object',
                            properties: {
                              changes: {
                                type: 'object',
                                properties: {
                                  from: {
                                    type: 'number'
                                  },
                                  to: {
                                    type: 'number'
                                  }
                                }
                              }
                            }
                          }
                        ]
                      }
                    })
      expect(@schema[:oneOf]).to include(include(title: 'foo'))
      expect(@schema[:oneOf].detect { |x| x[:title] == 'foo' })
        .to include(properties: {
                      'foo' => {
                        oneOf: [
                          {
                            type: 'object',
                            properties: {
                              matches: {
                                type: 'string'
                              }
                            }
                          },
                          {
                            type: 'object',
                            properties: {
                              changes: {
                                type: 'object',
                                properties: {
                                  from: {
                                    type: 'string'
                                  },
                                  to: {
                                    type: 'string'
                                  }
                                }
                              }
                            }
                          }
                        ]
                      }
                    })
    end

    it 'returns schema for related models foreign keys' do
      expect(@schema[:oneOf]).to include(include(title: 'sub_model_id'))
      expect(@schema[:oneOf].detect { |x| x[:title] == 'sub_model_id' })
        .to include(properties: {
                      'sub_model_id' => {
                        oneOf: [
                          {
                            type: 'object',
                            properties: {
                              matches: {
                                type: 'number'
                              }
                            }
                          },
                          {
                            type: 'object',
                            properties: {
                              changes: {
                                type: 'object',
                                properties: {
                                  from: {
                                    type: 'number'
                                  },
                                  to: {
                                    type: 'number'
                                  }
                                }
                              }
                            }
                          }
                        ]
                      }
                    })
    end
  end
end
