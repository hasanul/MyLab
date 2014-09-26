class UsersController < ApplicationController
  before_filter :authenticate_user!
  def edit
    @user = current_user
    render "edit_password"
  end

  def update_password
    @user = User.find(current_user.id)
    if @user.update_with_password(user_params)
      # Sign in the user by passing validation in case his password changed
      sign_in @user, :bypass => true
      flash[:notice] = 'Password was changed successfully.'
      redirect_to edit_user_path
    else
      flash[:alert] = 'Failed Password changing.'
      render "edit_password"
    end
  end

  private

  def user_params
    # NOTE: Using `strong_parameters` gem
    params.required(:user).permit(:current_password, :password, :password_confirmation)
  end
end