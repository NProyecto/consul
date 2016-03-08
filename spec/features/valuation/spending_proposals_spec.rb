require 'rails_helper'

feature 'Valuation spending proposals' do

  background do
    @valuator = create(:valuator, user: create(:user, username: 'Rachel', email: 'rachel@valuators.org'))
    login_as(@valuator.user)
  end

  scenario 'Disabled with a feature flag' do
    Setting['feature.spending_proposals'] = nil
    expect{ visit valuation_spending_proposals_path }.to raise_exception(FeatureFlags::FeatureDisabled)
  end

  scenario 'Index shows spending proposals assigned to current valuator' do
    spending_proposal1 = create(:spending_proposal)
    spending_proposal2 = create(:spending_proposal)

    spending_proposal1.valuators << @valuator

    visit valuation_spending_proposals_path

    expect(page).to have_content(spending_proposal1.title)
    expect(page).to_not have_content(spending_proposal2.title)
  end

  scenario 'Index shows no spending proposals to admins no valuators' do
    spending_proposal1 = create(:spending_proposal)
    spending_proposal2 = create(:spending_proposal)
    spending_proposal1.valuators << @valuator

    logout
    login_as create(:administrator).user
    visit valuation_spending_proposals_path

    expect(page).to_not have_content(spending_proposal1.title)
    expect(page).to_not have_content(spending_proposal2.title)
  end

  scenario 'Index shows assignments info' do
    spending_proposal1 = create(:spending_proposal)
    spending_proposal2 = create(:spending_proposal)
    spending_proposal3 = create(:spending_proposal)

    valuator1 = create(:valuator, user: create(:user))
    valuator2 = create(:valuator, user: create(:user))
    valuator3 = create(:valuator, user: create(:user))

    spending_proposal1.valuator_ids = [@valuator.id]
    spending_proposal2.valuator_ids = [@valuator.id, valuator1.id, valuator2.id]
    spending_proposal3.valuator_ids = [@valuator.id, valuator3.id]

    visit valuation_spending_proposals_path

    within("#spending_proposal_#{spending_proposal1.id}") do
      expect(page).to have_content("Rachel")
    end

    within("#spending_proposal_#{spending_proposal2.id}") do
      expect(page).to have_content("3 valuators assigned")
    end

    within("#spending_proposal_#{spending_proposal3.id}") do
      expect(page).to have_content("2 valuators assigned")
    end
  end

  scenario "Index filtering by geozone", :js do
    geozone = create(:geozone, name: "District 9")
    spending_proposal1 = create(:spending_proposal, title: "Realocate visitors", geozone: geozone)
    spending_proposal2 = create(:spending_proposal, title: "Destroy the city")
    spending_proposal1.valuators << @valuator
    spending_proposal2.valuators << @valuator

    visit valuation_spending_proposals_path
    expect(page).to have_link("Realocate visitors")
    expect(page).to have_link("Destroy the city")

    select "District 9", from: "geozone_id"

    expect(page).to have_link("Realocate visitors")
    expect(page).to_not have_link("Destroy the city")

    select "All city", from: "geozone_id"

    expect(page).to have_link("Destroy the city")
    expect(page).to_not have_link("Realocate visitors")

    select "All zones", from: "geozone_id"
    expect(page).to have_link("Realocate visitors")
    expect(page).to have_link("Destroy the city")
  end

  scenario "Current filter is properly highlighted" do
    filters_links = {'valuating' => 'Under valuation',
                     'valuation_finished' => 'Valuation finished'}

    visit valuation_spending_proposals_path

    expect(page).to_not have_link(filters_links.values.first)
    filters_links.keys.drop(1).each { |filter| expect(page).to have_link(filters_links[filter]) }

    filters_links.each_pair do |current_filter, link|
      visit valuation_spending_proposals_path(filter: current_filter)

      expect(page).to_not have_link(link)

      (filters_links.keys - [current_filter]).each do |filter|
        expect(page).to have_link(filters_links[filter])
      end
    end
  end

  scenario "Index filtering by valuation status" do
    valuating = create(:spending_proposal, title: "Ongoing valuation")
    valuated = create(:spending_proposal, title: "Old idea", valuation_finished: true)
    valuating.valuators << @valuator
    valuated.valuators << @valuator

    visit valuation_spending_proposals_path(filter: 'valuation_open')

    expect(page).to have_content("Ongoing valuation")
    expect(page).to_not have_content("Old idea")

    visit valuation_spending_proposals_path(filter: 'valuating')

    expect(page).to have_content("Ongoing valuation")
    expect(page).to_not have_content("Old idea")

    visit valuation_spending_proposals_path(filter: 'valuation_finished')

    expect(page).to_not have_content("Ongoing valuation")
    expect(page).to have_content("Old idea")
  end

  feature 'Show' do
    scenario 'visible for assigned valuators' do
      administrator = create(:administrator, user: create(:user, username: 'Ana', email: 'ana@admins.org'))
      valuator2 = create(:valuator, user: create(:user, username: 'Rick', email: 'rick@valuators.org'))
      spending_proposal = create(:spending_proposal,
                                  geozone: create(:geozone),
                                  association_name: 'People of the neighbourhood',
                                  price: 1234,
                                  feasible: false,
                                  feasible_explanation: 'It is impossible',
                                  administrator: administrator)
      spending_proposal.valuators << [@valuator, valuator2]

      visit valuation_spending_proposals_path

      click_link spending_proposal.title

      expect(page).to have_content(spending_proposal.title)
      expect(page).to have_content(spending_proposal.description)
      expect(page).to have_content(spending_proposal.author.name)
      expect(page).to have_content(spending_proposal.association_name)
      expect(page).to have_content(spending_proposal.geozone.name)
      expect(page).to have_content('1234')
      expect(page).to have_content('Not feasible')
      expect(page).to have_content('It is impossible')
      expect(page).to have_content('Ana (ana@admins.org)')

      within('#assigned_valuators') do
        expect(page).to have_content('Rachel (rachel@valuators.org)')
        expect(page).to have_content('Rick (rick@valuators.org)')
      end
    end

    scenario 'visible for admins' do
      logout
      login_as create(:administrator).user

      administrator = create(:administrator, user: create(:user, username: 'Ana', email: 'ana@admins.org'))
      valuator2 = create(:valuator, user: create(:user, username: 'Rick', email: 'rick@valuators.org'))
      spending_proposal = create(:spending_proposal,
                                  geozone: create(:geozone),
                                  association_name: 'People of the neighbourhood',
                                  price: 1234,
                                  feasible: false,
                                  feasible_explanation: 'It is impossible',
                                  administrator: administrator)
      spending_proposal.valuators << [@valuator, valuator2]

      visit valuation_spending_proposal_path(spending_proposal)

      expect(page).to have_content(spending_proposal.title)
      expect(page).to have_content(spending_proposal.description)
      expect(page).to have_content(spending_proposal.author.name)
      expect(page).to have_content(spending_proposal.association_name)
      expect(page).to have_content(spending_proposal.geozone.name)
      expect(page).to have_content('1234')
      expect(page).to have_content('Not feasible')
      expect(page).to have_content('It is impossible')
      expect(page).to have_content('Ana (ana@admins.org)')

      within('#assigned_valuators') do
        expect(page).to have_content('Rachel (rachel@valuators.org)')
        expect(page).to have_content('Rick (rick@valuators.org)')
      end
    end

    scenario 'not visible for not assigned valuators' do
      logout
      login_as create(:valuator).user

      administrator = create(:administrator, user: create(:user, username: 'Ana', email: 'ana@admins.org'))
      valuator2 = create(:valuator, user: create(:user, username: 'Rick', email: 'rick@valuators.org'))
      spending_proposal = create(:spending_proposal,
                                  geozone: create(:geozone),
                                  association_name: 'People of the neighbourhood',
                                  price: 1234,
                                  feasible: false,
                                  feasible_explanation: 'It is impossible',
                                  administrator: administrator)
      spending_proposal.valuators << [@valuator, valuator2]

      expect { visit valuation_spending_proposal_path(spending_proposal) }.to raise_error "Not Found"
    end

  end

  feature 'Valuate' do
    background do
      @spending_proposal = create(:spending_proposal,
                                geozone: create(:geozone),
                                administrator: create(:administrator))
      @spending_proposal.valuators << @valuator
    end

    scenario 'Dossier empty by default' do
      visit valuation_spending_proposals_path
      click_link @spending_proposal.title

      within('#price') { expect(page).to have_content('Undefined') }
      within('#price_first_year') { expect(page).to have_content('Undefined') }
      within('#time_scope') { expect(page).to have_content('Undefined') }
      within('#feasibility') { expect(page).to have_content('Undefined') }
      expect(page).to_not have_content('Valuation finished')
      expect(page).to_not have_content('Internal comments')
    end

    scenario 'Edit dossier' do
      visit valuation_spending_proposals_path
      within("#spending_proposal_#{@spending_proposal.id}") do
        click_link "Edit"
      end

      fill_in 'spending_proposal_price', with: '12345'
      fill_in 'spending_proposal_price_first_year', with: '9876'
      fill_in 'spending_proposal_price_explanation', with: 'Very cheap idea'
      choose  'spending_proposal_feasible_true'
      fill_in 'spending_proposal_feasible_explanation', with: 'Everything is legal and easy to do'
      fill_in 'spending_proposal_time_scope', with: '19 months'
      fill_in 'spending_proposal_internal_comments', with: 'Should be double checked by the urbanism area'
      click_button 'Save changes'

      expect(page).to have_content "Dossier updated"

      visit valuation_spending_proposals_path
      click_link @spending_proposal.title

      within('#price') { expect(page).to have_content('12345') }
      within('#price_first_year') { expect(page).to have_content('9876') }
      expect(page).to have_content('Very cheap idea')
      within('#time_scope') { expect(page).to have_content('19 months') }
      within('#feasibility') { expect(page).to have_content('Feasible') }
      expect(page).to_not have_content('Valuation finished')
      expect(page).to have_content('Internal comments')
      expect(page).to have_content('Should be double checked by the urbanism area')
    end

    scenario 'Finish valuation' do
      visit valuation_spending_proposal_path(@spending_proposal)
      click_link 'Edit dossier'

      check 'spending_proposal_valuation_finished'
      click_button 'Save changes'

      visit valuation_spending_proposals_path
      expect(page).to_not have_content @spending_proposal.title
      click_link 'Valuation finished'

      expect(page).to have_content @spending_proposal.title
      click_link @spending_proposal.title
      expect(page).to have_content('Valuation finished')
    end

    scenario 'Validates price formats' do
      visit valuation_spending_proposals_path
      within("#spending_proposal_#{@spending_proposal.id}") do
        click_link "Edit"
      end

      fill_in 'spending_proposal_price', with: '12345,98'
      fill_in 'spending_proposal_price_first_year', with: '9876.6'
      click_button 'Save changes'

      expect(page).to have_content('2 errors')
      expect(page).to have_content('Only integer numbers', count: 2)
    end
  end

end
