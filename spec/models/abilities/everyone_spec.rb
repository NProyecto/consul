require 'rails_helper'
require 'cancan/matchers'

describe "Abilities::Everyone" do
  subject(:ability) { Ability.new(user) }

  let(:user) { nil }
  let(:debate) { create(:debate) }
  let(:proposal) { create(:proposal) }

  it { should be_able_to(:index, Debate) }
  it { should be_able_to(:show, debate) }
  it { should_not be_able_to(:edit, Debate) }
  it { should_not be_able_to(:vote, Debate) }
  it { should_not be_able_to(:flag, Debate) }
  it { should_not be_able_to(:unflag, Debate) }

  it { should be_able_to(:index, Proposal) }
  it { should be_able_to(:show, proposal) }
  it { should_not be_able_to(:edit, Proposal) }
  it { should_not be_able_to(:vote, Proposal) }
  it { should_not be_able_to(:flag, Proposal) }
  it { should_not be_able_to(:unflag, Proposal) }

  it { should be_able_to(:show, Comment) }

  it { should be_able_to(:index, SpendingProposal) }
  it { should be_able_to(:welcome, SpendingProposal) }
  it { should_not be_able_to(:create, SpendingProposal) }

  describe "Participatory budgeting results page is public" do
    before { Setting["feature.spending_proposal_features.open_results_page"] = true }
    it { should be_able_to(:stats, SpendingProposal) }
    it { should be_able_to(:results, SpendingProposal) }
  end

  describe "Participatory budgeting results page is not public" do
    before { Setting["feature.spending_proposal_features.open_results_page"] = nil }
    it { should_not be_able_to(:stats, SpendingProposal) }
    it { should_not be_able_to(:results, SpendingProposal) }
  end

  pending "only authors can access new and create for ProposalNotifications"
end