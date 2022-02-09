class V1::FormsController < ApplicationController
  def configuration
    @form = FormDefinition.where(id: params[:id]).first
    configuration = @form && (@form.locked_configuration || @form.current_configuration)

    respond_with_configuration(configuration)
  end

  def current_configuration
    @form = FormDefinition.where(id: params[:id]).first
    configuration = @form && @form.current_configuration

    respond_with_configuration(configuration)
  end

  def locked_configuration
    @form = FormDefinition.where(id: params[:id]).first
    configuration = @form && @form.locked_configuration

    respond_with_configuration(configuration)
  end

  private

  def respond_with_configuration(configuration)
    respond_to do |format|
      format.json do
        if configuration
          render json: configuration_response(configuration)
        else
          render json: { error: "not found" }, status: :not_found
        end
      end
    end
  end

  def configuration_response(configuration)
    {
      id: configuration.id,
      payload: JSON.parse(configuration.payload),
      configuration_type: configuration.configuration_type,
      schema_spec: configuration.schema_spec,
      created_at: configuration.created_at,
      updated_at: configuration.updated_at
    }
  end
end
