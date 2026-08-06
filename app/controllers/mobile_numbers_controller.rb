class MobileNumbersController < ApplicationController
  skip_before_action :require_mobile_number

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if mobile_number_params[:mobile_number].present? && @user.update(mobile_number_params)
      redirect_to root_path, notice: "Thanks!"
    else
      @user.errors.add(:mobile_number, "can't be blank") if mobile_number_params[:mobile_number].blank?
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def mobile_number_params
    params.require(:user).permit(:mobile_number)
  end
end
