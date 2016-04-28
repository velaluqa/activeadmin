require 'remote/sql/dumper'

RSpec.describe Sql::Dumper do
  describe 'without column filters' do
    before :each do
      @study = create(:study, :production)
      @center1 = create(
        :center,
        name: 'center1',
        code: 'center1',
        created_at: DateTime.new(2015, 5, 7, 12, 25),
        updated_at: DateTime.new(2015, 5, 7, 12, 25),
        domino_unid: 'ABC1',
        study: @study
      )
      @center2 = create(
        :center,
        name: 'center2',
        code: 'center2',
        created_at: DateTime.new(2015, 5, 7, 12, 25),
        updated_at: DateTime.new(2015, 5, 7, 12, 25),
        domino_unid: 'ABC2',
        study: @study
      )
      @dumper = Sql::Dumper.new(@study.centers)
    end

    describe '#columns' do
      it 'returns an array of columns' do
        expect(@dumper.columns.map(&:name))
          .to eq %w(code created_at domino_unid id name study_id updated_at)
      end
    end

    describe '#dump_upserts' do
      it 'dumps found records to given io' do
        io = StringIO.new
        @dumper.dump_upserts(io)
        expect(io.string).to eq <<SQL
BEGIN;
WITH "new_values" ("code", "created_at", "domino_unid", "id", "name", "study_id", "updated_at") as (
  values
('center1', '2015-05-07 12:25:00'::timestamp, 'ABC1', #{@center1.id}, 'center1', #{@study.id}, '2015-05-07 12:25:00'::timestamp),
('center2', '2015-05-07 12:25:00'::timestamp, 'ABC2', #{@center2.id}, 'center2', #{@study.id}, '2015-05-07 12:25:00'::timestamp)
),
"upsert" AS
(
  UPDATE "centers" "m"
  SET
    "code" = "nv"."code"::varchar(),
    "created_at" = "nv"."created_at"::timestamp,
    "domino_unid" = "nv"."domino_unid"::varchar(),
    "id" = "nv"."id"::integer,
    "name" = "nv"."name"::varchar(),
    "study_id" = "nv"."study_id"::integer,
    "updated_at" = "nv"."updated_at"::timestamp
  FROM "new_values" "nv"
  WHERE "m"."id" = "nv"."id"
  RETURNING "m".*
)
INSERT INTO "centers" ("code", "created_at", "domino_unid", "id", "name", "study_id", "updated_at")
SELECT "code"::varchar(), "created_at"::timestamp, "domino_unid"::varchar(), "id"::integer, "name"::varchar(), "study_id"::integer, "updated_at"::timestamp
FROM "new_values"
WHERE NOT EXISTS (SELECT 1 FROM "upsert" "up" WHERE "up"."id" = "new_values"."id");
COMMIT;
SQL
      end
    end
  end

  describe 'with :override_values options' do
    before :each do
      @study = create(:study, :production)
      @center1 = create(
        :center,
        name: 'center1',
        code: 'center1',
        created_at: DateTime.new(2015, 5, 7, 12, 25),
        updated_at: DateTime.new(2015, 5, 7, 12, 25),
        domino_unid: 'ABC1',
        study: @study
      )
      @center2 = create(
        :center,
        name: 'center2',
        code: 'center2',
        created_at: DateTime.new(2015, 5, 7, 12, 25),
        updated_at: DateTime.new(2015, 5, 7, 12, 25),
        domino_unid: 'ABC2',
        study: @study
      )
      @dumper = Sql::Dumper.new(
        @study.centers,
        override_values: { code: 'center{{:id}}' }
      )
    end

    describe '#dump_upserts' do
      it 'dumps found records to given io' do
        io = StringIO.new
        @dumper.dump_upserts(io)
        expect(io.string).to eq <<SQL
BEGIN;
WITH "new_values" ("code", "created_at", "domino_unid", "id", "name", "study_id", "updated_at") as (
  values
('center#{@center1.id}', '2015-05-07 12:25:00'::timestamp, 'ABC1', #{@center1.id}, 'center1', #{@study.id}, '2015-05-07 12:25:00'::timestamp),
('center#{@center2.id}', '2015-05-07 12:25:00'::timestamp, 'ABC2', #{@center2.id}, 'center2', #{@study.id}, '2015-05-07 12:25:00'::timestamp)
),
"upsert" AS
(
  UPDATE "centers" "m"
  SET
    "code" = "nv"."code"::varchar(),
    "created_at" = "nv"."created_at"::timestamp,
    "domino_unid" = "nv"."domino_unid"::varchar(),
    "id" = "nv"."id"::integer,
    "name" = "nv"."name"::varchar(),
    "study_id" = "nv"."study_id"::integer,
    "updated_at" = "nv"."updated_at"::timestamp
  FROM "new_values" "nv"
  WHERE "m"."id" = "nv"."id"
  RETURNING "m".*
)
INSERT INTO "centers" ("code", "created_at", "domino_unid", "id", "name", "study_id", "updated_at")
SELECT "code"::varchar(), "created_at"::timestamp, "domino_unid"::varchar(), "id"::integer, "name"::varchar(), "study_id"::integer, "updated_at"::timestamp
FROM "new_values"
WHERE NOT EXISTS (SELECT 1 FROM "upsert" "up" WHERE "up"."id" = "new_values"."id");
COMMIT;
SQL
      end
    end
  end

  describe 'with :columns options' do
    before :each do
      @study = create(:study, :production)
      @center1 = create(
        :center,
        name: 'center1',
        code: 'center1',
        created_at: DateTime.new(2015, 5, 7, 12, 25),
        updated_at: DateTime.new(2015, 5, 7, 12, 25),
        domino_unid: 'ABC1',
        study: @study
      )
      @center2 = create(
        :center,
        name: 'center2',
        code: 'center2',
        created_at: DateTime.new(2015, 5, 7, 12, 25),
        updated_at: DateTime.new(2015, 5, 7, 12, 25),
        domino_unid: 'ABC2',
        study: @study
      )
      @dumper = Sql::Dumper.new(
        @study.centers,
        columns: %w(name code created_at)
      )
    end

    describe '#update_columns' do
      it 'should return all columns without the ignored ones' do
        expect(@dumper.update_columns.map(&:name))
          .to eq %w(code created_at name)
      end
    end

    describe '#dump_upserts' do
      it 'dumps found records to given io' do
        io = StringIO.new
        @dumper.dump_upserts(io)
        expect(io.string).to eq <<SQL
BEGIN;
WITH "new_values" ("code", "created_at", "name") as (
  values
('center1', '2015-05-07 12:25:00'::timestamp, 'center1'),
('center2', '2015-05-07 12:25:00'::timestamp, 'center2')
),
"upsert" AS
(
  UPDATE "centers" "m"
  SET
    "code" = "nv"."code"::varchar(),
    "created_at" = "nv"."created_at"::timestamp,
    "name" = "nv"."name"::varchar()
  FROM "new_values" "nv"
  WHERE "m"."id" = "nv"."id"
  RETURNING "m".*
)
INSERT INTO "centers" ("code", "created_at", "name")
SELECT "code"::varchar(), "created_at"::timestamp, "name"::varchar()
FROM "new_values"
WHERE NOT EXISTS (SELECT 1 FROM "upsert" "up" WHERE "up"."id" = "new_values"."id");
COMMIT;
SQL
      end
    end
  end

  describe 'with ignore_update_columns' do
    before :each do
      @study = create(:study, :production)
      @center1 = create(
        :center,
        name: 'center1',
        code: 'center1',
        created_at: DateTime.new(2015, 5, 7, 12, 25),
        updated_at: DateTime.new(2015, 5, 7, 12, 25),
        domino_unid: 'ABC1',
        study: @study
      )
      @center2 = create(
        :center,
        name: 'center2',
        code: 'center2',
        created_at: DateTime.new(2015, 5, 7, 12, 25),
        updated_at: DateTime.new(2015, 5, 7, 12, 25),
        domino_unid: 'ABC2',
        study: @study
      )
      @dumper = Sql::Dumper.new(
        @study.centers,
        ignore_update_columns: %w(created_at)
      )
    end

    describe '#update_columns' do
      it 'should return all columns without the ignored ones' do
        expect(@dumper.update_columns.map(&:name))
          .to eq %w(code domino_unid id name study_id updated_at)
      end
    end

    describe '#dump_upserts' do
      it 'dumps found records to given io' do
        io = StringIO.new
        @dumper.dump_upserts(io)
        expect(io.string).to eq <<SQL
BEGIN;
WITH "new_values" ("code", "created_at", "domino_unid", "id", "name", "study_id", "updated_at") as (
  values
('center1', '2015-05-07 12:25:00'::timestamp, 'ABC1', #{@center1.id}, 'center1', #{@study.id}, '2015-05-07 12:25:00'::timestamp),
('center2', '2015-05-07 12:25:00'::timestamp, 'ABC2', #{@center2.id}, 'center2', #{@study.id}, '2015-05-07 12:25:00'::timestamp)
),
"upsert" AS
(
  UPDATE "centers" "m"
  SET
    "code" = "nv"."code"::varchar(),
    "domino_unid" = "nv"."domino_unid"::varchar(),
    "id" = "nv"."id"::integer,
    "name" = "nv"."name"::varchar(),
    "study_id" = "nv"."study_id"::integer,
    "updated_at" = "nv"."updated_at"::timestamp
  FROM "new_values" "nv"
  WHERE "m"."id" = "nv"."id"
  RETURNING "m".*
)
INSERT INTO "centers" ("code", "created_at", "domino_unid", "id", "name", "study_id", "updated_at")
SELECT "code"::varchar(), "created_at"::timestamp, "domino_unid"::varchar(), "id"::integer, "name"::varchar(), "study_id"::integer, "updated_at"::timestamp
FROM "new_values"
WHERE NOT EXISTS (SELECT 1 FROM "upsert" "up" WHERE "up"."id" = "new_values"."id");
COMMIT;
SQL
      end
    end
  end
end
