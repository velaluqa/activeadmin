# coding: utf-8
require 'migration/migrate_required_series'

describe Migration::MigrateRequiredSeries do
  def point_in_time(i)
    Time.new(2017, 8, 1) + i.day
  end

  describe '::required_series_changes' do
    let!(:visit) { create(:visit) }
    let!(:image_series) { create(:image_series, visit: visit) }

    describe 'image_series_id added' do
      describe 'tqc_state already set' do
        let!(:visit_version) do
          Version.new(
            event: 'update',
            item_type: 'Visit',
            item_id: visit.id,
            object_changes: {
              'required_series' => [
                {
                  'rs1' => {
                    'tqc_state' => 2,
                    'image_series_id' => nil
                  }
                }, {
                  'rs1' => {
                    'image_series_id' => image_series.id
                  }
                }
              ]
            }
          )
        end

        let(:changes) { Migration::MigrateRequiredSeries.required_series_changes(visit_version) }

        it 'returns correct changes' do
          expect(changes)
            .to eq(
                  [
                    {
                      visit_id: visit.id,
                      name: 'rs1',
                      changes: {
                        'image_series_id' => [nil, image_series.id],
                        'tqc_state' => [nil, 'pending']
                      }
                    }
                  ]
                )

        end
      end
      describe 'tqc_state unset' do
        let!(:visit_version) do
          Version.new(
            event: 'update',
            item_type: 'Visit',
            item_id: visit.id,
            object_changes: {
              'required_series' => [
                {
                  'rs1' => {
                    'image_series_id' => nil
                  }
                }, {
                  'rs1' => {
                    'image_series_id' => image_series.id
                  }
                }
              ]
            }
          )
        end

        let(:changes) { Migration::MigrateRequiredSeries.required_series_changes(visit_version) }

        it 'returns correct changes' do
          expect(changes)
            .to eq(
                  [
                    {
                      visit_id: visit.id,
                      name: 'rs1',
                      changes: {
                        'image_series_id' => [nil, image_series.id],
                        'tqc_state' => [nil, 'pending']
                      }
                    }
                  ]
                )

        end
      end
    end
    describe 'image_series_id removed' do
      describe 'tqc_state already set' do
        let!(:visit_version) do
          Version.new(
            event: 'update',
            item_type: 'Visit',
            item_id: visit.id,
            object_changes: {
              'required_series' => [
                {
                  'rs1' => {
                    'tqc_state' => 1,
                    'image_series_id' => image_series.id
                  }
                }, {
                  'rs1' => {
                    'image_series_id' => nil
                  }
                }
              ]
            }
          )
        end

        let(:changes) { Migration::MigrateRequiredSeries.required_series_changes(visit_version) }

        it 'returns correct changes' do
          expect(changes)
            .to eq(
                  [
                    {
                      visit_id: visit.id,
                      name: 'rs1',
                      changes: {
                        'image_series_id' => [image_series.id, nil],
                        'tqc_state' => ['issues', nil]
                      }
                    }
                  ]
                )
        end
      end
      describe 'tqc_state unset' do
        let!(:visit_version) do
          Version.new(
            event: 'update',
            item_type: 'Visit',
            item_id: visit.id,
            object_changes: {
              'required_series' => [
                {
                  'rs1' => {
                    'image_series_id' => image_series.id
                  }
                }, {
                  'rs1' => {
                    'image_series_id' => nil
                  }
                }
              ]
            }
          )
        end

        let(:changes) { Migration::MigrateRequiredSeries.required_series_changes(visit_version) }

        it 'returns correct changes' do
          expect(changes)
            .to eq(
                  [
                    {
                      visit_id: visit.id,
                      name: 'rs1',
                      changes: {
                        'image_series_id' => [image_series.id, nil],
                      }
                    }
                  ]
                )
        end
      end
    end
  end

  describe '::merged_study_configurations' do
    let(:commits) do
      [
        {
          ref: '1',
          time: point_in_time(1),
          yaml: {
            'visit_types' => {
            }
          }
        }, {
          ref: '2',
          time: point_in_time(3),
          yaml: {
            'visit_types' => {
              'type1' => {}
            }
          }
        }, {
          ref: '3',
          time: point_in_time(5),
          yaml: {
            'visit_types' => {
              'type1' => {
                'required_series' => {
                  'SPECT' => {}
                }
              }
            }
          }
        }, {
          ref: '4',
          time: point_in_time(7),
          yaml: {
            'visit_types' => {
              'type1' => {
                'required_series' => {
                  'SPECT' => {}
                }
              },
              'type2' => {
                'required_series' => {
                  'SPECT' => {}
                }
              }
            }
          }
        }, {
          ref: '5',
          time: point_in_time(9),
          yaml: {
            'visit_types' => {
              'type1' => {
                'required_series' => {
                  'SPECT1' => {},
                  'SPECT2' => {}
                }
              }
            }
          }
        }
      ]
    end
    let(:locks) do
      [
        {
          time: point_in_time(2),
          locked_version: '1'
        }, {
          time: point_in_time(6),
          locked_version: nil
        }, {
          time: point_in_time(8),
          locked_version: '4'
        }
      ]
    end

    let(:merged_configurations) do
      Migration::MigrateRequiredSeries.merged_study_configurations(commits, locks)
    end

    it 'merges correctly' do
      expect(merged_configurations)
        .to eq(
              [
                {
                  ref: '1',
                  time: point_in_time(1),
                  yaml: {
                    'visit_types' => {
                    }
                  }
                }, {
                  ref: '3',
                  time: point_in_time(6),
                  yaml: {
                    'visit_types' => {
                      'type1' => {
                        'required_series' => {
                          'SPECT' => {}
                        }
                      }
                    }
                  }
                }, {
                  ref: '4',
                  time: point_in_time(7),
                  yaml: {
                    'visit_types' => {
                      'type1' => {
                        'required_series' => {
                          'SPECT' => {}
                        }
                      },
                      'type2' => {
                        'required_series' => {
                          'SPECT' => {}
                        }
                      }
                    }
                  }
                }
              ]
            )
    end
  end

  describe '::migrate_study' do
    before(:each) do
      PaperTrail.enabled = false
      ActiveRecord::Base.record_timestamps = false
    end

    after(:each) do
      PaperTrail.enabled = true
      ActiveRecord::Base.record_timestamps = true
    end

    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient) { create(:patient, center: center) }
    let!(:visit1) { create(:visit, patient: patient) }
    let!(:visit2) { create(:visit, patient: patient) }
    let!(:visit3) { create(:visit, patient: patient) }

    let!(:config_history) {
      [
        {
          ref: '1',
          time: point_in_time(1),
          yaml: {
            'visit_types' => {}
          }
        },
        {
          ref: '2',
          time: point_in_time(3),
          yaml: {
            'visit_types' => {
              'type1' => {
                'required_series' => {
                  'rs1' => {},
                  'rs2' => {},
                  'later_removed' => {}
                }
              },
              'type2' => {
                'required_series' => {
                  'rs2' => {},
                  'rs3' => {}
                }
              }
            }
          }
        },
        {
          ref: '3',
          time: point_in_time(12),
          yaml: {
            'visit_types' => {
              'type1' => {
                'required_series' => {
                  'rs1' => {},
                  'rs2' => {}
                }
              },
              'type2' => {
                'required_series' => {
                  'rs2' => {},
                  'rs3' => {},
                  'additional' => {}
                }
              }
            }
          }
        }
      ]
    }

    let!(:version1) {
      Version.create!(
        item_type: 'Visit',
        item_id: visit1.id,
        event: 'create',
        object: nil,
        object_changes: {
          'visit_type' => [nil, 'type1']
        },
        created_at: point_in_time(2),
        study_id: study.id
      )
    }
    let!(:version2) {
      Version.create!(
        item_type: 'Visit',
        item_id: visit2.id,
        event: 'create',
        object: nil,
        object_changes: {
          'visit_type' => [nil, 'type1']
        },
        created_at: point_in_time(4),
        study_id: study.id
      )
    }
    let!(:version3) {
      Version.create!(
        item_type: 'Visit',
        item_id: visit2.id,
        event: 'update',
        object: {
          'visit_type' => 'type1'
        },
        object_changes: {
          'visit_type' => ['type1', 'type2']
        },
        created_at: point_in_time(5),
        study_id: study.id
      )
    }
    let!(:version4) do
      Version.create!(
        item_type: 'Visit',
        item_id: visit2.id,
        event: 'update',
        object: {
          'visit_type' => 'type2'
        },
        object_changes: {
          'required_series' => [
            {}, {
              'rs1' => { 'domino_unid' => '1234567890' }
            }
          ]
        },
        created_at: point_in_time(6),
        study_id: study.id
      )
    end
    let!(:version5) do
      Version.create!(
        item_type: 'Visit',
        item_id: visit2.id,
        event: 'update',
        object: {
          'visit_type' => 'type2',
          'required_series' => {
            'rs1' => { 'domino_unid' => '1234567890' }
          }
        },
        object_changes: {
          'required_series' => [
            {
              'rs1' => { 'domino_unid' => '1234567890' }
            }, {
              'rs1' => { 'domino_unid' => '1234567890' },
              'rs2' => { 'domino_unid' => '0123456789' }
            }
          ]
        },
        created_at: point_in_time(7),
        study_id: study.id
      )
    end
    let!(:version6) do
      Version.create!(
        item_type: 'Visit',
        item_id: visit2.id,
        event: 'update',
        object: {
          'visit_type' => 'type2',
          'required_series' => {
            'rs1' => { 'domino_unid' => '1234567890' },
            'rs2' => { 'domino_unid' => '0123456789' }
          }
        },
        object_changes: {
          'required_series' => [
            {
              'rs1' => { 'domino_unid' => '1234567890' },
              'rs2' => { 'domino_unid' => '0123456789' }
            }, {
              'rs1' => { 'domino_unid' => '1234567890' },
              'rs2' => { 'domino_unid' => '0123456789' }
            }
          ]
        },
        created_at: point_in_time(8),
        study_id: study.id
      )
    end
    let!(:version7) {
      Version.create!(
        item_type: 'Visit',
        item_id: visit3.id,
        event: 'create',
        object: nil,
        object_changes: {
          'patient_id' => [nil, patient.id]
        },
        created_at: point_in_time(9),
        study_id: study.id
      )
    }
    let!(:version8) {
      Version.create!(
        item_type: 'Visit',
        item_id: visit3.id,
        event: 'update',
        object: {
          'patient_id' => patient.id
        },
        object_changes: {
          'visit_type' => [nil, 'type1']
        },
        created_at: point_in_time(10),
        study_id: study.id
      )
    }
    let!(:version9) {
      Version.create!(
        item_type: 'Visit',
        item_id: visit3.id,
        event: 'destroy',
        object: {
          'patient_id' => patient.id,
          'visit_type' => 'type1'
        },
        object_changes: nil,
        created_at: point_in_time(11),
        study_id: study.id
      )
    }

    before(:each) do
      Migration::MigrateRequiredSeries.migrate_study(study.id, config_history)
    end

    let(:required_series_versions) { Version.where(item_type: 'RequiredSeries').order(:created_at).map(&:attributes) }
    let(:visit_versions) { Version.where(item_type: 'Visit').map(&:attributes) }

    it 'creates required series for create with visit type' do
      expect(required_series_versions)
        .to include(
              include(
                'object_changes' => include(
                  'visit_id' => [nil, visit2.id],
                  'name' => [nil, 'rs2']
                ),
                'created_at' => version2.created_at
              )
            )
    end
    it 'adds additional required series for update with new visit type' do
      expect(required_series_versions)
        .to include(
              include(
                'object_changes' => include(
                  'visit_id' => [nil, visit2.id],
                  'name' => [nil, 'rs3']
                ),
                'created_at' => version3.created_at
              )
            )
    end
    it 'removes required series for update with new visit type' do
      expect(required_series_versions)
        .to include(
              include(
                'event' => 'destroy',
                'object' => include(
                  'visit_id' => visit2.id,
                  'name' => 'rs1'
                ),
                'created_at' => version3.created_at
              )
            )
    end
    it 'creates required series for update with visit type' do
      expect(required_series_versions)
        .to include(
              include(
                'object_changes' => include(
                  'visit_id' => [nil, visit3.id],
                  'name' => [nil, 'rs2']
                ),
                'created_at' => version8.created_at
              )
            )
    end
    it 'removes required series for visit destroy' do
      expect(required_series_versions)
        .to include(
              include(
                'event' => 'destroy',
                'object' => include(
                  'visit_id' => visit3.id,
                  'name' => 'rs1'
                ),
                'created_at' => version9.created_at
              ),
              include(
                'event' => 'destroy',
                'object' => include(
                  'visit_id' => visit3.id,
                  'name' => 'rs2'
                ),
                'created_at' => version9.created_at
              )
            )
    end

    it 'adds additional required series on configuration update' do
      expect(required_series_versions)
        .to include(
              # Adds required series `rs1` and `rs2` for visit with
              # visit type `type1`.
              include(
                'object_changes' => include(
                  'visit_id' => [nil, visit1.id],
                  'name' => [nil, 'rs1']
                ),
                'created_at' => point_in_time(3)
              ))
      expect(required_series_versions)
        .to include(
              include(
                'object_changes' => include(
                  'visit_id' => [nil, visit1.id],
                  'name' => [nil, 'rs2']
                ),
                'created_at' => point_in_time(3)
              )
            )
    end
    it 'adds additional required series when visit type is modified on configuration update' do
      expect(required_series_versions)
        .to include(
              include(
                'object_changes' => include(
                  'visit_id' => [nil, visit2.id],
                  'name' => [nil, 'additional']
                ),
                'created_at' => point_in_time(12)
              )
            )
    end
    it 'removes required series on configuration update' do
      expect(required_series_versions)
        .to include(
              include(
                'event' => 'destroy',
                'object' => include(
                  'visit_id' => visit1.id,
                  'name' => 'later_removed'
                ),
                'created_at' => point_in_time(12)
              )
            )
    end

    it 'migrates visit´s required_series change to RequiredSeries version' do
      expect(required_series_versions)
        .to include(
              include(
                'event' => 'update',
                'object' => include(
                  'visit_id' => visit2.id,
                  'name' => 'rs1'
                ),
                'object_changes' => include(
                  'domino_unid' => [nil, '1234567890']
                ),
                'created_at' => version4.created_at
              )
            )
      expect(required_series_versions)
        .to include(
              include(
                'event' => 'update',
                'object' => include(
                  'visit_id' => visit2.id,
                  'name' => 'rs2'
                ),
                'object_changes' => include(
                  'domino_unid' => [nil, '0123456789']
                ),
                'created_at' => version5.created_at
              )
            )
      expect(required_series_versions)
        .not_to include(
                  include(
                    'event' => 'update',
                    'object' => include(
                      'visit_id' => visit2.id,
                      'name' => 'rs1'
                    ),
                    'object_changes' => include(
                      'domino_unid' => [nil, '1234567890']
                    ),
                    'created_at' => version6.created_at
                  )
                )
      expect(required_series_versions)
        .not_to include(
                  include(
                    'event' => 'update',
                    'object' => include(
                      'visit_id' => visit2.id,
                      'name' => 'rs2'
                    ),
                    'object_changes' => include(
                      'domino_unid' => [nil, '0123456789']
                    ),
                    'created_at' => version6.created_at
                  )
                )
    end
  end
end
