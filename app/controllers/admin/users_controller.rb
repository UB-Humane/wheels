class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :edit, :update, :destroy ]

  def index
    @pagy, @users = pagy(User.includes(:productions, :distributions).order(:name), limit: 20)
  end

  def new
    @user = User.new
    @productions = Production.all
    @distributions = Distribution.all
  end

  def create
    @user = User.new(user_params)
    if @user.save
      sync_location_assignments
      redirect_to admin_users_path, notice: "User added."
    else
      @productions = Production.all
      @distributions = Distribution.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @productions = Production.all
    @distributions = Distribution.all
  end

  def update
    attributes = user_params
    attributes = attributes.except(:password, :password_confirmation) if attributes[:password].blank?
    if @user.update(attributes)
      sync_location_assignments
      redirect_to admin_users_path, notice: "User updated."
    else
      @productions = Production.all
      @distributions = Distribution.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot remove yourself."
      return
    end
    @user.destroy
    redirect_to admin_users_path, notice: "User removed."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :mobile_number, :password, :password_confirmation, :superadmin)
  end

  def sync_location_assignments
    return if @user.superadmin?

    @user.user_productions.destroy_all
    @user.user_distributions.destroy_all

    (params[:production_access_enabled] || {}).each_key do |production_id|
      role = params.dig(:production_access_role, production_id) || "volunteer"
      @user.user_productions.create!(production_id: production_id, role: role)
    end

    (params[:distribution_access_enabled] || {}).each_key do |distribution_id|
      role = params.dig(:distribution_access_role, distribution_id) || "volunteer"
      @user.user_distributions.create!(distribution_id: distribution_id, role: role)
    end
  end
end
