class CasesController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_case

  def cancel_read
    if(@case.state == :in_progress || @case.state == :reopened_in_progress)
      @case.state = (@case.state == :reopened_in_progress ? :reopened : :unread)
      @case.save

      if(@case.state == :unread and @case.flag == :reader_testing)
        @case.form_answer.destroy
        @case.destroy
      end

      respond_to do |format|
        format.json { render :json => {:success => true} }
      end  
    else
      respond_to do |format|
        format.json { render :json => {:success => false, :error => 'Case is not in progress', :error_code => 2} }
      end
    end
  end

  protected

  def authorize_user_for_case
    raise CanCan::AccessDenied.new('You are not authorized to access this case!', :read, @case) unless ((@case.session.state == :production and @case.session.readers.include?(current_user)) or
                                                                                                        (@case.session.state == :testing and @case.session.validators.include?(current_user)))
  end

  def find_case
    begin
      @case = Case.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render :json => {:error => 'Case not found', :error_code => 1}
      return false
    end

    authorize_user_for_case
  end
end
