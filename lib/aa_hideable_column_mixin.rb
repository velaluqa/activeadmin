module ActiveAdmin
  module HideableColumns
    module ResourceMixin
      def self.included(base)
        base.class_eval do
          attr_accessor :hideable_columns
        end
      end
    end
  end

  module HideableColumnMixin
    
    module DSL
      def hideable_columns(columns: [], hidden_by_default: [])

        controller_name = controller.resource_class.name.underscore
        config.hideable_columns = columns
        collection_action :select_hideable_columns, :method => :post do
          session["#{controller_name}_columns"] = params[:columns]
          redirect_to request.referer
        end

        sidebar :hideable_columns, :only => :index do
          render(
            :partial => 'admin/shared/select_hideable_columns',
            :locals => {
              :columns => columns,
              :selected_columns => session["#{controller_name}_columns"] || [],
              url: url_for(action: :select_hideable_columns)
            }
          )
        end
      end
    end
  end

  module Views
    module IndexAsTableMixin
      def self.included(base)
        base.class_eval do
          def column_with_hiding(*args, &block)

            options = args.extract_options!
            column_key = args[1] || args[0]

            if display_column?(column_key)
              column_without_hiding(*args, options, &block)
            end 
          end

          alias_method :column_without_hiding, :column
          alias_method :column, :column_with_hiding

          def display_column?(column_name)
            return true unless column_name.is_a?(Symbol) 

            hideable_columns = active_admin_config.hideable_columns

            return true if hideable_columns.nil?
            return true if hideable_columns.empty?
            return true unless hideable_columns.include?(column_name)
            return true if display_columns.empty?

            display_columns.include?(column_name)
          end

          def display_columns
            (session[session_display_columns_key] || []).map(&:to_sym)
          end

          def session_display_columns_key
            "#{active_admin_config.resource_name.name.underscore}_columns".to_sym
          end
        end
      end
    end
  end
end



