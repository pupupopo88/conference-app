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
  let(:stamp_code) { SponsorVisitToken.generate(event_slug: event.slug, sponsor_key: "smartbank.co.jp") }

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
      expect(passport_label["class"]).to include("text-stone-700", "bg-stone-100", "leading-relaxed")
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
      expect(Nokogiri::HTML(response.body).at_css("[data-passport-complete]")).to be_nil
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

    it "celebrates a completed passport" do
      sign_in(user)
      SponsorCatalog.with_booth(event.slug).each do |sponsor|
        FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: sponsor[:key])
      end

      get sponsor_passport_path(event_slug: event.slug)

      document = Nokogiri::HTML(response.body)
      celebration = document.at_css("[data-passport-complete]")
      expect(celebration.text).to include("All Complete!", "すべてのブースのスタンプが揃いました")
      expect(document.at_css("[role='progressbar']")["aria-valuenow"]).to eq("22")
      expect(response.body).not_to include("次のバッジまで")
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

  describe "GET /sponsor_passports/:event_slug/stamps/new" do
    it "shows a confirmation without recording a visit" do
      sign_in(user)

      expect {
        get new_sponsor_passport_stamp_path(event.slug, code: stamp_code)
      }.not_to change(SponsorVisit, :count)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("SmartBank, Inc.")
      expect(response.body).to include("Gold Sponsor")
      expect(response.body).to include("スタンプを獲得する")
      expect(response.body).to include("スタンプを押しています…")
      sponsor_logo = Nokogiri::HTML(response.body).at_css("img[data-sponsor-logo]")
      sponsor_logo_stage = Nokogiri::HTML(response.body).at_css("[data-sponsor-logo-stage]")
      expect(sponsor_logo["src"]).to eq("https://kaigionrails.org/2026/images/sponsors/S313_smartbank.co.jp_gold.png")
      expect(sponsor_logo["alt"]).to eq("")
      expect(sponsor_logo["class"]).to include("h-auto", "w-full", "bg-white", "object-contain")
      expect(sponsor_logo["class"]).not_to include("rounded")
      expect(sponsor_logo_stage["class"]).to include("passport-logo-panel")
      expect(Nokogiri::HTML(response.body).at_css("[data-new-stamp-celebration]")).to be_nil
      expect(response.body).to include("訪問の記念に、スタンプをひとつ。")
      back_link = Nokogiri::HTML(response.body).at_css("main a[href='#{sponsor_passport_path(event_slug: event.slug)}']")
      expect(back_link.text.strip).to eq("スタンプ帳に戻る")
      stamp_collection_path = sponsor_passport_stamps_path(event.slug)
      expect(response.body).to include(%(method="post" action="#{stamp_collection_path}"))
      collection_form = Nokogiri::HTML(response.body).at_css("form[action='#{stamp_collection_path}']")
      expect(collection_form.at_css("input[name='code']")["value"]).to eq(stamp_code)
      expect(collection_form["data-turbo"]).to be_nil
      expect(response.body).not_to include("担当者から展示の説明を聞きましたか？")
      expect(Nokogiri::HTML(response.body).at_css("h1").text.strip).to eq("SmartBank, Inc.")
      collection_button = collection_form.at_css("button")
      expect(collection_button["data-turbo-submits-with"]).to eq("スタンプを押しています…")
      expect(collection_button["aria-live"]).to eq("polite")
      expect(collection_button["class"]).to include("rounded-lg", "bg-theme-primary-700")
    end

    it "redirects an existing visit to its result" do
      sign_in(user)
      visit = FactoryBot.create(:sponsor_visit, user: user, event: event, sponsor_key: "smartbank.co.jp")

      expect {
        get new_sponsor_passport_stamp_path(event.slug, code: stamp_code)
      }.not_to change(SponsorVisit, :count)

      expect(response).to redirect_to(sponsor_passport_stamp_path(event.slug, visit))
    end

    it "shows non-booth sponsor labels" do
      sign_in(user)
      code = SponsorVisitToken.generate(event_slug: event.slug, sponsor_key: "mov.am")

      get new_sponsor_passport_stamp_path(event.slug, code: code)

      sponsor_labels = Nokogiri::HTML(response.body).css("[data-sponsor-label]").map { |label| label.text.strip }
      expect(sponsor_labels).to eq(["Print sticker sponsor"])
      expect(Nokogiri::HTML(response.body).at_css("[data-sponsor-label]")["class"]).to include("rounded-full", "bg-stone-100")
    end

    it "redirects a logged-out user to login" do
      stamp_path = new_sponsor_passport_stamp_path(event.slug, code: stamp_code)

      get stamp_path

      expect(response).to redirect_to(login_path(return_to: stamp_path))
      expect(SponsorVisit).not_to exist
    end
  end

  describe "POST /sponsor_passports/:event_slug/stamps" do
    it "records a visit for a logged-in user" do
      sign_in(user)
      FactoryBot.create(:sponsor_visit, user: FactoryBot.create(:user), event: event, sponsor_key: "esm.co.jp")

      expect {
        post sponsor_passport_stamps_path(event.slug), params: {code: stamp_code}, headers: {"Accept" => "text/vnd.turbo-stream.html, text/html"}
      }.to change(SponsorVisit, :count).by(1)

      expect(SponsorVisit.last).to have_attributes(
        user: user,
        event: event,
        sponsor_key: "smartbank.co.jp"
      )
      visit = SponsorVisit.last
      expect(response).to redirect_to(sponsor_passport_stamp_path(event.slug, visit))
      expect(response.location).not_to include(stamp_code)
      expect(response).to have_http_status(:see_other)

      follow_redirect!

      expect(response).to have_http_status(:success)
      expect(response.body).to include("スタンプ獲得！")
      expect(response.body).to include("SmartBank, Inc.")
      expect(response.body).to include("#01")
      expect(response.body).to include("1個目のパスポートスタンプ")
      expect(response.body).to include("passport-stamp-stage--new")
      expect(response.body).to include("data-new-stamp-celebration")
      expect(response.body).to include("passport-confetti")
      expect(response.body).to include("community-stamp-count--updated")
      expect(response.body).to include("1 / 22 社")
      expect(response.body).to include("次のバッジまで、あと4社")
      expect(response.body).not_to include("Hello, Sponsors!")
      expect(response.body).to include(%(role="progressbar"))
      result_progress = Nokogiri::HTML(response.body).at_css("[role='progressbar']")
      expect(result_progress.css("[title]").pluck("title")).to eq([
        "バッジ獲得ライン：5社",
        "バッジ獲得ライン：12社"
      ])
      expect(Nokogiri::HTML(response.body).at_css("[data-community-stamp-count]").text.strip).to eq("2個")
      expect(Nokogiri::HTML(response.body).xpath("//*[normalize-space(text())='true']")).to be_empty
      expect(response.body).to include("みんなで集めたスタンプ")
      expect(response.body).to include("次はどこへ？")
      next_sponsor_keys = Nokogiri::HTML(response.body).css("[data-next-sponsor]").pluck("data-next-sponsor")
      expect(next_sponsor_keys.size).to eq(2)
      expect(next_sponsor_keys).not_to include("smartbank.co.jp")
      next_sponsor_labels = Nokogiri::HTML(response.body).css("[data-next-sponsor] [data-sponsor-label]").map { |label| label.text.strip }
      expect(next_sponsor_labels).to include("Print sticker sponsor")
      expect(next_sponsor_labels).not_to include("Booth")
      expect(response.body).to include(%(href="#{sponsor_passport_path(event_slug: event.slug)}"))
    end

    it "does not duplicate an existing visit" do
      sign_in(user)

      post sponsor_passport_stamps_path(event.slug), params: {code: stamp_code}

      expect {
        post sponsor_passport_stamps_path(event.slug), params: {code: stamp_code}
      }.not_to change(SponsorVisit, :count)

      follow_redirect!

      expect(response.body).to include("獲得済みのスタンプです")
      expect(response.body).not_to include("passport-stamp-stage--new")
      expect(response.body).not_to include("data-new-stamp-celebration")
      expect(response.body).not_to include("community-stamp-count--updated")
    end

    it "returns not found for an unknown sponsor" do
      sign_in(user)

      expect {
        post sponsor_passport_stamps_path(event.slug), params: {code: "x" * SponsorVisitToken::TOKEN_LENGTH}
      }.not_to change(SponsorVisit, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "does not record a visit for a sponsor without a booth" do
      sign_in(user)
      code = SponsorVisitToken.generate(event_slug: event.slug, sponsor_key: "coincheck.com")

      expect {
        post sponsor_passport_stamps_path(event.slug), params: {code: code}
      }.not_to change(SponsorVisit, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "redirects a logged-out user to login" do
      post sponsor_passport_stamps_path(event.slug), params: {code: stamp_code}

      expect(response).to redirect_to(login_path)
      expect(SponsorVisit).not_to exist
    end

    it "does not accept a code generated for another event" do
      sign_in(user)
      other_event_code = SponsorVisitToken.generate(event_slug: "2025", sponsor_key: "smartbank.co.jp")

      expect {
        post sponsor_passport_stamps_path(event.slug), params: {code: other_event_code}
      }.not_to change(SponsorVisit, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "does not expose the old sponsor-key URL" do
      expect {
        Rails.application.routes.recognize_path("/sponsors/smartbank.co.jp/visit", method: :get)
      }.to raise_error(ActionController::RoutingError)
    end

    it "celebrates completing every sponsor booth" do
      sign_in(user)
      SponsorCatalog.with_booth(event.slug).reject { |sponsor| sponsor[:key] == "smartbank.co.jp" }.each do |sponsor|
        FactoryBot.create(:sponsor_visit, user: user, event: event, sponsor_key: sponsor[:key])
      end

      post sponsor_passport_stamps_path(event.slug), params: {code: stamp_code}

      follow_redirect!

      expect(response).to have_http_status(:success)
      expect(response.body).to include("全スポンサー完全制覇！")
      expect(response.body).to include("22 / 22 社")
      expect(response.body).to include("すべてのスポンサーブースを訪問しました")
      expect(response.body).not_to include("次はどこへ？")
    end

    it "suggests only the final unvisited booth when one remains" do
      sign_in(user)
      remaining_sponsor_key = "esm.co.jp"
      SponsorCatalog.with_booth(event.slug).reject { |sponsor| ["smartbank.co.jp", remaining_sponsor_key].include?(sponsor[:key]) }.each do |sponsor|
        FactoryBot.create(:sponsor_visit, user: user, event: event, sponsor_key: sponsor[:key])
      end

      post sponsor_passport_stamps_path(event.slug), params: {code: stamp_code}
      follow_redirect!

      next_sponsor_keys = Nokogiri::HTML(response.body).css("[data-next-sponsor]").pluck("data-next-sponsor")
      expect(next_sponsor_keys).to eq([remaining_sponsor_key])
    end
  end

  describe "GET /sponsor_passports/:event_slug/stamps/:id" do
    it "shows non-booth sponsor labels on the result" do
      sign_in(user)
      visit = FactoryBot.create(:sponsor_visit, user: user, event: event, sponsor_key: "mov.am")

      get sponsor_passport_stamp_path(event.slug, visit)

      sponsor_labels = Nokogiri::HTML(response.body).css("[data-sponsor-label]").map { |label| label.text.strip }
      expect(sponsor_labels).to eq(["Print sticker sponsor"])
    end

    it "does not show another user's visit" do
      sign_in(user)
      another_users_visit = FactoryBot.create(
        :sponsor_visit,
        user: FactoryBot.create(:user),
        event: event,
        sponsor_key: "smartbank.co.jp"
      )

      get sponsor_passport_stamp_path(event.slug, another_users_visit)

      expect(response).to have_http_status(:not_found)
    end

    it "does not show the user's visit from another event" do
      sign_in(user)
      other_event = FactoryBot.create(:event, name: "Kaigi on Rails 2025", slug: "2025")
      visit = FactoryBot.create(:sponsor_visit, user: user, event: other_event, sponsor_key: "smartbank.co.jp")

      get sponsor_passport_stamp_path(event.slug, visit)

      expect(response).to have_http_status(:not_found)
    end
  end
end
