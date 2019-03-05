require "rails_helper"

feature "Admin poll questions" do

  background do
    login_as(create(:administrator).user)
  end

  it_behaves_like "translatable",
                  "poll_question",
                  "edit_admin_question_path",
                  %w[title]

  scenario "Index" do
    poll1 = create(:poll)
    poll2 = create(:poll)
    question1 = create(:poll_question, poll: poll1)
    question2 = create(:poll_question, poll: poll2)

    visit admin_poll_path(poll1)
    expect(page).to have_content(poll1.name)

    within("#poll_question_#{question1.id}") do
      expect(page).to have_content(question1.title)
      expect(page).to have_content("Edit answers")
      expect(page).to have_content("Edit")
      expect(page).to have_content("Delete")
    end

    visit admin_poll_path(poll2)
    expect(page).to have_content(poll2.name)

    within("#poll_question_#{question2.id}") do
      expect(page).to have_content(question2.title)
      expect(page).to have_content("Edit answers")
      expect(page).to have_content("Edit")
      expect(page).to have_content("Delete")
    end
  end

  scenario "Show" do
    geozone = create(:geozone)
    poll = create(:poll, geozone_restricted: true, geozone_ids: [geozone.id])
    question = create(:poll_question, poll: poll)

    visit admin_poll_path(poll)
    click_link "#{question.title}"

    expect(page).to have_content(question.title)
    expect(page).to have_content(question.author.name)
  end

  scenario "Create" do
    poll = create(:poll, name: "Movies")
    title = "Star Wars: Episode IV - A New Hope"

    visit admin_poll_path(poll)
    click_link "Create question"

    expect(page).to have_content("Create question to poll Movies")
    expect(page).to have_selector("input[id='poll_question_poll_id'][value='#{poll.id}']",
                                   visible: false)
    fill_in "Question", with: title

    click_button "Save"

    expect(page).to have_content(title)
  end

  scenario "Create from proposal" do
    create(:poll, name: "Proposals")
    proposal = create(:proposal)

    visit admin_proposal_path(proposal)

    expect(page).not_to have_content("This proposal has reached the required supports")
    click_link "Add this proposal to a poll to be voted"

    expect(page).to have_current_path(new_admin_question_path, ignore_query: true)
    expect(page).to have_field("Question", with: proposal.title)

    select "Proposals", from: "poll_question_poll_id"

    click_button "Save"

    expect(page).to have_content(proposal.title)
  end

  scenario "Create from successful proposal" do
    create(:poll, name: "Proposals")
    proposal = create(:proposal, :successful)

    visit admin_proposal_path(proposal)

    expect(page).to have_content("This proposal has reached the required supports")
    click_link "Add this proposal to a poll to be voted"

    expect(page).to have_current_path(new_admin_question_path, ignore_query: true)
    expect(page).to have_field("Question", with: proposal.title)

    select "Proposals", from: "poll_question_poll_id"

    click_button "Save"

    expect(page).to have_content(proposal.title)
  end

  scenario "Update" do
    poll = create(:poll)
    question1 = create(:poll_question, poll: poll)

    visit admin_poll_path(poll)

    within("#poll_question_#{question1.id}") do
      click_link "Edit"
    end

    old_title = question1.title
    new_title = "Potatoes are great and everyone should have one"
    fill_in "Question", with: new_title

    click_button "Save"

    expect(page).to have_content "Changes saved"
    expect(page).to have_content new_title
    expect(page).not_to have_content(old_title)
  end

  scenario "Destroy" do
    poll = create(:poll)
    question1 = create(:poll_question, poll: poll)
    question2 = create(:poll_question, poll: poll)

    visit admin_poll_path(poll)

    within("#poll_question_#{question1.id}") do
      click_link "Delete"
    end

    expect(page).not_to have_content(question1.title)
    expect(page).to have_content(question2.title)
  end

  pending "Mark all city by default when creating a poll question from a successful proposal"

  context "Poll select box" do

    let(:poll) { create(:poll, name_en: "Name in English",
                               name_es: "Nombre en Español",
                               summary_en: "Summary in English",
                               summary_es: "Resumen en Español",
                               description_en: "Description in English",
                               description_es: "Descripción en Español") }

    let(:question) { create(:poll_question, poll: poll,
                                            title_en: "Question in English",
                                            title_es: "Pregunta en Español") }

    scenario "translates the poll name in options", :js do
      visit edit_admin_question_path(question)

      expect(page).to have_select("poll_question_poll_id", options: [poll.name_en])

      select("Español", from: "locale-switcher")

      expect(page).to have_select("poll_question_poll_id", options: [poll.name_es])
    end

    scenario "uses fallback if name is not translated to current locale", :js do
      unless globalize_french_fallbacks.first == :es
        skip("Spec only useful when French falls back to Spanish")
      end

      visit edit_admin_question_path(question)

      expect(page).to have_select("poll_question_poll_id", options: [poll.name_en])

      select("Français", from: "locale-switcher")

      expect(page).to have_select("poll_question_poll_id", options: [poll.name_es])
    end
  end

  def globalize_french_fallbacks
    Globalize.fallbacks(:fr).reject { |locale| locale.match(/fr/) }
  end
end
