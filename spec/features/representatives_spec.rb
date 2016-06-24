require 'rails_helper'

feature 'Representatives' do

  scenario "Select a representative" do
    forum1 = create(:forum)
    forum2 = create(:forum)
    user = create(:user, :level_two)
    login_as(user)

    visit forums_path

    click_link forum1.name
    click_button "Delegate on #{forum1.name}"

    expect(page).to have_content "You have updated your representative"
    expect(page).to have_content "You are delegating your votes on #{forum1.name}"
    expect(page).to have_css("#forum_#{forum1.id}.active")
  end

  scenario "Delete a representative" do
    forum = create(:forum)
    user = create(:user, :level_two, representative: forum)

    login_as(user)
    visit forums_path

    expect(page).to have_content "You are delegating your votes on #{forum.name}"

    click_link "Deactivate"

    expect(page).to have_content "You do not have a representative anymore."
    expect(page).to have_content "You are not delegating your votes"
  end

  scenario "User not logged in" do
    forum = create(:forum)

    visit forums_path
    click_link forum.name

    expect(page).to_not have_selector(:button, "Delegate on #{forum.name}")
    expect(page).to have_content "Sign in to delegate"
  end

  scenario "User not verified" do
    unverified_user = create(:user)
    forum = create(:forum)

    login_as(unverified_user)
    visit forums_path
    click_link forum.name

    expect(page).to_not have_selector(:button, "Delegate on #{forum.name}")
    expect(page).to have_content "Verify your account to delegate"
  end
end