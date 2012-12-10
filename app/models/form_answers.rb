class FormAnswer
  include MongoMapper::Document

  key :reader, Integer
  key :read, Integer
  key :form_id, Integer
  key :form_timestamp, Integer
  key :submitted_at, Time
  key :answers, Hash
  key :signature, Binary

end
