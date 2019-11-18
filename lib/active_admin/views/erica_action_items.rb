module ActiveAdmin
  module Views
    # Overriding ActiveAdmin defaults.
    class EricaActionItems < Component
      def build(action_items)
        action_items.each do |action_item|
          span class: "action_item #{action_item.name}" do
            instance_exec(&action_item.block)
          end
        end
      end
    end
  end
end
