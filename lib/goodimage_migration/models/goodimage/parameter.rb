module GoodImageMigration
  module GoodImage
    class Parameter
      include DataMapper::Resource

      storage_names[:goodimage] = 'parameter'

      property :id, Serial

      property :docu_name, String
      property :comment, String

      property :name, String
      property :dicom, String
      property :datatype, String
      property :vr, String

      property :modification_timestamp, Time

      has n, :parameter_to_segments, child_key: 'parameter__id'
      has n, :segments, through: :parameter_to_segments
      has n, :parameter_ranges, 'ParameterRanges', through: :parameter_to_segments
      has n, :patient_parameters, child_key: 'parameter__id'
      has n, :image_dicom_key_values, 'ImageDICOMKeyValue', child_key: 'parameter__id'
    end
  end
end
