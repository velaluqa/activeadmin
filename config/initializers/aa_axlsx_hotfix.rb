# this fixes an apparent bug in activeadmin-axlsx 2.0.1 (which is the most recent version that still supports activeadmin 0.5.X
# without htis fix, every generation of an xlsx export for a resource appends to the old exports done since the server last restarted
module ActiveAdmin
  module Axlsx
    module ResourceExtension
      def xlsx_builder
        @xlsx_builder = ActiveAdmin::Axlsx::Builder.new(resource_class)        
      end
    end
  end
end
