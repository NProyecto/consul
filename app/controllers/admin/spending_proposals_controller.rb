class Admin::SpendingProposalsController < Admin::BaseController
  include FeatureFlags
  feature_flag :spending_proposals

  has_filters %w{valuation_open without_admin managed valuating valuation_finished all}, only: :index

  load_and_authorize_resource

  def index
    @spending_proposals = SpendingProposal.scoped_filter(params, @current_filter).order(confidence_score: :desc, created_at: :desc).page(params[:page])
  end

  def show
  end

  def edit
    load_admins
    load_valuators
    load_tags
  end

  def update
    if @spending_proposal.update(spending_proposal_params)
      redirect_to admin_spending_proposal_path(@spending_proposal, SpendingProposal.filter_params(params)),
                  notice: t("flash.actions.update.spending_proposal")
    else
      load_admins
      load_valuators
      load_tags
      render :edit
    end
  end

  def results
    @spending_proposals = SpendingProposal.feasible.valuation_finished.
                                          by_geozone(params[:geozone_id]).
                                          order(ballot_lines_count: :desc, price: :desc).
                                          page(params[:page]).per(300)

    load_geozone
    @initial_budget = Ballot.initial_budget(@geozone)
  end

  def summary
    @spending_proposals = SpendingProposal.limit_results(SpendingProposal, params).group(:geozone).sum(:price).sort_by{|geozone, count| geozone.present? ? geozone.name : "ZZ"}
  end

  private

    def spending_proposal_params
      params.require(:spending_proposal).permit(:title, :description, :external_url, :geozone_id, :association_name, :administrator_id, :tag_list, valuator_ids: [])
    end

    def load_admins
      @admins = Administrator.includes(:user).all
    end

    def load_valuators
      @valuators = Valuator.includes(:user).all.order("description ASC").order("users.email ASC")
    end

    def load_tags
      @tags = ActsAsTaggableOn::Tag.spending_proposal_tags
    end

    def load_geozone
      @geozone = (params[:geozone_id].blank? || params[:geozone_id] == 'all') ? nil : Geozone.find(params[:geozone_id])
    end

end
