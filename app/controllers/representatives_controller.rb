class RepresentativesController < ApplicationController

  before_action :authenticate_user!
  skip_authorization_check

  def create
    representative = Forum.find(representative_params[:id])
    current_user.representative = representative
    current_user.accepted_delegation_alert = false
    current_user.save!

    if current_user.ballot.present?
      current_user.ballot.ballot_lines.destroy_all
      current_user.ballot.update(geozone: nil)
    end

    redirect_to forums_path, notice: t("flash.actions.create.representative")
  end

  def destroy
    current_user.update!(representative: nil)
    redirect_to forums_path, notice: t("flash.actions.destroy.representative")
  end

  private

    def representative_params
      params.require(:forum).permit(:id)
    end

end
