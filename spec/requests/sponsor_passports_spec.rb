require "rails_helper"

RSpec.describe "Sponsor passports", type: :request do
  let!(:event) do
    FactoryBot.create(
      :event,
      :make_ongoing,
      name: "Kaigi on Rails 2026",
      slug: "2026"
    )
  end
  let(:user) { FactoryBot.create(:user) }

  describe "GET /sponsor_passports/:event_slug" do
    it "shows visit progress and visited sponsors" do
      sign_in(user)
      FactoryBot.create(:sponsor_visit, user: user, event: event, sponsor_key: "smartbank.co.jp")

      get sponsor_passport_path(event_slug: event.slug)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("1 / 22 社")
      expect(response.body).to include("SmartBank, Inc.")
      expect(response.body).to include("ESM, Inc.")
      expect(response.body).not_to include("Coincheck, Inc.")
      expect(response.body).to include("バッジ未獲得")
      expect(response.body).not_to include("Hello, Sponsors!")
      expect(response.body).not_to include("Halfway There!")
      expect(response.body).not_to include("All Complete!")
      expect(response.body).to include("次のバッジまで、あと4社")
      expect(response.body).not_to include("Kaigi on Rails 2026")
      expect(response.body).to include(%(role="progressbar"))
      progress_section = Nokogiri::HTML(response.body).at_css("[role='progressbar']")
      expect(progress_section.css("[title]").pluck("title")).to eq([
        "バッジ獲得ライン：5社",
        "バッジ獲得ライン：12社"
      ])
      expect(response.body).not_to include("<ol")
      expect(response.body).to include("獲得済み ✓")
      expect(response.body).to include("#01")
      expect(response.body).to include("1個目に獲得したパスポートスタンプ")
      expect(response.body).to include("未訪問")
      visible_statuses = Nokogiri::HTML(response.body).xpath("//*[normalize-space(text())='獲得済み ✓' or normalize-space(text())='未訪問']")
      expect(visible_statuses).to be_empty
      expect(response.body).to include(%(href="#{sponsor_passport_path(event_slug: event.slug)}"))
      expect(response.body).to include("スポンサースタンプラリー")
      document = Nokogiri::HTML(response.body)
      expect(document.css("[data-sponsor-plan]").pluck("data-sponsor-plan")).to eq(["ruby", "gold"])
      expect(document.at_css("[data-sponsor-plan='ruby'] h2").text.strip).to eq("Ruby Sponsors")
      expect(document.at_css("[data-sponsor-plan='gold'] h2").text.strip).to eq("Gold Sponsors")
      sponsor_labels = Nokogiri::HTML(response.body).css("[data-sponsor-label]").map { |label| label.text.strip }
      expect(sponsor_labels).to include("Print sticker sponsor", "Scholarship sponsor")
      expect(sponsor_labels).not_to include("Booth")
      passport_label = document.at_css("[data-sponsor-plan='ruby'] [data-sponsor-label]")
      expect(passport_label["class"]).to include("text-gray-500")
      expect(passport_label["class"]).not_to include("rounded-full", "bg-gray-100")
      menu_link = Nokogiri::HTML(response.body).at_css("nav a[href='#{sponsor_passport_path(event_slug: event.slug)}']")
      expect(menu_link.text.strip).to eq("Sponsor Passport")
    end

    it "shows the number of stamps collected across the conference" do
      sign_in(user)
      FactoryBot.create(:sponsor_visit, user: user, event: event, sponsor_key: "smartbank.co.jp")
      other_user = FactoryBot.create(:user)
      FactoryBot.create(:sponsor_visit, user: other_user, event: event, sponsor_key: "smartbank.co.jp")
      FactoryBot.create(:sponsor_visit, user: other_user, event: event, sponsor_key: "esm.co.jp")
      FactoryBot.create(:sponsor_visit, user: other_user, event: event, sponsor_key: "coincheck.com")
      other_event = FactoryBot.create(:event, name: "Kaigi on Rails 2025", slug: "2025")
      FactoryBot.create(:sponsor_visit, user: other_user, event: other_event, sponsor_key: "smartbank.co.jp")

      get sponsor_passport_path(event_slug: event.slug)

      community_count = Nokogiri::HTML(response.body).at_css("[data-community-stamp-count]")
      expect(community_count.text.strip).to eq("3個")
      expect(response.body).to include("みんなで集めたスタンプ")
    end

    it "reveals a badge title only after the milestone is reached" do
      sign_in(user)
      SponsorCatalog.with_booth(event.slug).first(5).each do |sponsor|
        FactoryBot.create(:sponsor_visit, user: user, event: event, sponsor_key: sponsor[:key])
      end

      get sponsor_passport_path(event_slug: event.slug)

      expect(response.body).to include("Hello, Sponsors!")
      expect(response.body).not_to include("Halfway There!")
      expect(response.body).to include("次のバッジまで、あと7社")
    end

    it "shows an empty state when no sponsors have been visited" do
      sign_in(user)

      get sponsor_passport_path(event_slug: event.slug)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("0 / 22 社")
      expect(response.body).to include("スポンサーのQRコードを読み取って、スタンプを集めましょう")
      expect(response.body).to include("次のバッジまで、あと5社")
      expect(response.body).to include("バッジ未獲得")
      expect(response.body).to include("SmartBank, Inc.")
      expect(response.body).to include("未訪問")
    end

    it "shows the English product name and localized content for an English user" do
      FactoryBot.create(:locale_setting, user: user, preferred_locale: "en")
      sign_in(user)

      get sponsor_passport_path(event_slug: event.slug)

      document = Nokogiri::HTML(response.body)
      expect(document.at_css("h1").text.strip).to eq("Sponsor Passport")
      expect(document.at_css("nav a[href='#{sponsor_passport_path(event_slug: event.slug)}']").text.strip).to eq("Sponsor Passport")
      expect(response.body).to include("No badges yet")
      expect(response.body).to include("Collected together")
      expect(response.body).to include("Visit 5 more booths to unlock your next badge")
      expect(response.body).not_to include("Hello, Sponsors!")
      expect(document.at_css("[data-community-stamp-count]").text.strip).to eq("0 stamps")
    end

    it "returns not found for a past event" do
      past_event = FactoryBot.create(:event, name: "Kaigi on Rails 2025", slug: "2025")
      sign_in(user)

      get sponsor_passport_path(event_slug: past_event.slug)

      expect(response).to have_http_status(:not_found)
    end

    it "redirects a logged-out user to login" do
      get sponsor_passport_path(event_slug: event.slug)

      expect(response).to redirect_to(login_path(return_to: sponsor_passport_path(event_slug: event.slug)))
    end
  end
end
