require 'rails_helper'

feature 'Stats' do

  background do
    admin = create(:administrator)
    login_as(admin.user)
    visit root_path
  end

  context 'Summary' do

    scenario 'General' do
      create(:debate)
      2.times { create(:proposal) }
      3.times { create(:comment, commentable: Debate.first) }
      4.times { create(:visit) }
      6.times { create(:spending_proposal) }

      visit admin_stats_path

      expect(page).to have_content "Debates 1"
      expect(page).to have_content "Proposals 2"
      expect(page).to have_content "Comments 3"
      expect(page).to have_content "Visits 4"
      expect(page).to have_content "Investment projects 6"
    end

    scenario 'Votes' do
      debate = create(:debate)
      create(:vote, votable: debate)

      proposal = create(:proposal)
      2.times { create(:vote, votable: proposal) }

      comment = create(:comment)
      3.times { create(:vote, votable: comment) }

      spending_proposal = create(:spending_proposal)
      5.times { create(:vote, votable: spending_proposal) }

      visit admin_stats_path

      expect(page).to have_content "Debate votes 1"
      expect(page).to have_content "Proposal votes 2"
      expect(page).to have_content "Comment votes 3"
      expect(page).to have_content "Investment project votes 5"
      expect(page).to have_content "Total votes 11"
    end

    scenario 'Users' do
      1.times { create(:user, :level_three) }
      2.times { create(:user, :level_two) }
      3.times { create(:user) }

      visit admin_stats_path

      expect(page).to have_content "Level three users 1"
      expect(page).to have_content "Level two users 2"
      expect(page).to have_content "Verified users 3"
      expect(page).to have_content "Unverified users 4"
      expect(page).to have_content "Total users 7"
    end

  end

  scenario 'Level 2 user' do
    create(:geozone)
    visit account_path
    click_link 'Verify my account'
    verify_residence
    confirm_phone

    visit admin_stats_path

    expect(page).to have_content "Level two users 1"
  end

  context "Participatory Budgets" do

    scenario "Number of users that have voted a investment project" do
      spending_proposal = create(:spending_proposal, :feasible)

      ballot_with_votes = create(:ballot, spending_proposals: [spending_proposal])
      ballot_with_votes2 = create(:ballot, spending_proposals: [spending_proposal])
      ballot_without_votes = create(:ballot)

      visit admin_stats_path
      expect(page).to have_content "Budgets voted 2"
    end

    scenario "Number of users that have voted a investment project per geozone" do
      california = create(:geozone)

      create(:spending_proposal, :feasible, geozone: california)
      create(:spending_proposal, :feasible, geozone: california)
      create(:spending_proposal, :feasible, geozone: nil)

      SpendingProposal.all.each do |spending_proposal|
        create(:ballot, spending_proposals: [spending_proposal], geozone: spending_proposal.geozone)
      end

      visit admin_stats_path
      click_link "Participatory Budget"

      within("#geozone_#{california.id}") do
        expect(page).to have_content california.name
        expect(page).to have_content 2
      end
    end

    scenario "Number of users that have voted geozone/no-geozone wide proposals" do
      with_geozone = create(:spending_proposal, :feasible, geozone: create(:geozone))
      no_geozone   = create(:spending_proposal, :feasible, geozone: nil)

      both        = create(:ballot, spending_proposals: [with_geozone, no_geozone], geozone: with_geozone.geozone)
      geozoned    = create(:ballot, spending_proposals: [with_geozone], geozone: with_geozone.geozone)
      no_geozoned = create(:ballot, spending_proposals: [no_geozone], geozone: nil)


      visit admin_stats_path
      click_link "Participatory Budget"

      within("#city_voters") {expect(page).to have_content 2}
      within("#district_voters") {expect(page).to have_content 2}
      within("#in_both_voters") {expect(page).to have_content 1}
      within("#only_district_voters") {expect(page).to have_content 1}
      within("#only_city_voters") {expect(page).to have_content 1}
    end

    scenario "Number of votes in investment projects" do
      3.times { create(:ballot_line) }
      visit admin_stats_path
      expect(page).to have_content "Votes in investment projects 3"
    end
  end

  context "graphs" do

    scenario "custom graphs", :js do
      spending_proposal = create(:spending_proposal)

      visit admin_stats_path

      within("#stats") do
        click_link "Investment projects"
      end

      expect(page).to have_content "Investment projects (1)"
      within("#graph") do
        expect(page).to have_content spending_proposal.created_at.strftime("%Y-%m-%d")
      end
    end

    scenario "event graphs", :js do
      campaign = create(:campaign)

      visit root_path(track_id: campaign.track_id)
      visit admin_stats_path

      within("#stats") do
        click_link campaign.name
      end

      expect(page).to have_content "#{campaign.name} (1)"
      within("#graph") do
        event_created_at = Ahoy::Event.where(name: campaign.name).first.time
        expect(page).to have_content event_created_at.strftime("%Y-%m-%d")
      end
    end
  end

  context "Proposal notifications" do

    scenario "Summary stats" do
      proposal = create(:proposal)

      create(:proposal_notification, proposal: proposal)
      create(:proposal_notification, proposal: proposal)
      create(:proposal_notification)

      visit admin_stats_path
      click_link "Proposal notifications"

      within("#proposal_notifications_count") do
        expect(page).to have_content "3"
      end

      within("#proposals_with_notifications_count") do
        expect(page).to have_content "2"
      end
    end

    scenario "Index" do
      3.times { create(:proposal_notification) }

      visit admin_stats_path
      click_link "Proposal notifications"

      expect(page).to have_css(".proposal_notification", count: 3)

      ProposalNotification.all.each do |proposal_notification|
        expect(page).to have_content proposal_notification.title
        expect(page).to have_content proposal_notification.body
      end
    end

  end

  context "Direct messages" do

    scenario "Summary stats" do
      sender = create(:user, :level_two)

      create(:direct_message, sender: sender)
      create(:direct_message, sender: sender)
      create(:direct_message)

      visit admin_stats_path
      click_link "Direct messages"

      within("#direct_messages_count") do
        expect(page).to have_content "3"
      end

      within("#users_who_have_sent_message_count") do
        expect(page).to have_content "2"
      end
    end

  end

  context "Redeemable codes" do

    scenario "Total" do
      create(:user, redeemable_code: 'abc')
      create(:user, redeemable_code: 'def')
      create(:user, redeemable_code: 'ghi')

      visit admin_stats_path
      click_link "Redeemable codes"

      within("#redeemable_codes_count") do
        expect(page).to have_content "3"
      end
    end

    scenario "After campaign of June 17th 2016" do
      create(:user, redeemable_code: 'abd', verified_at: Date.new(2016, 6, 16))
      create(:user, redeemable_code: 'def', verified_at: Date.new(2016, 6, 17))
      create(:user, redeemable_code: 'ghi', verified_at: Date.new(2016, 6, 18))

      visit admin_stats_path
      click_link "Redeemable codes"

      within("#redeemable_codes_after_campaign_count") do
        expect(page).to have_content "2"
      end
    end

  end

end
