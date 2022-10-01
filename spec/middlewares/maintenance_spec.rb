require 'fileutils'

describe Middleware do

  describe "MaintenanceMiddleware" do
    let(:app) { Class.new { def call(env); end }.new }
    let(:maintenance) { ".maintenance" }
    let(:content_type) { "text/html" }
    let(:rack) { Middleware::Maintenance.new(app) }
    let(:data) { data = File.read("public/maintenance.html") }

    context "without maintenance file" do
      before(:each) do
        FileUtils.rm(maintenance) if File.exists?(maintenance)
      end
  
      it "calls the app" do
        expect(app).to receive(:call).once
        rack.call({})
      end
    end

    context "with maintenance file" do
      before(:each) do
        FileUtils.touch(maintenance)
        File.write(maintenance, "true")
      end

      after(:each) do
        FileUtils.rm(maintenance)
      end
  
      it "it does not call the app" do
        expect(app).not_to receive(:call)
        rack.call({})
      end

      it "returns the maintenance response" do
        expect(rack.call({})).to eq [503, {"Content-Type"=>content_type, "Content-Length"=>data.bytesize.to_s}, [data]]
      end
    end
  end
end