class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    attributes = user_params
    attributes = attributes.except(:password, :password_confirmation) if attributes[:password].blank?

    if @user.update(attributes)
      redirect_to edit_profile_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :mobile_number, :password, :password_confirmation)
  end
end
