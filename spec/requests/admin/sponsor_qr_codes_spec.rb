require "rails_helper"

RSpec.describe "Admin::SponsorQrCodes", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing, name: "Kaigi on Rails 2026", slug: "2026") }

  describe "GET /admin/sponsor_qr_codes" do
    it "shows stamp URLs for booth sponsors to an organizer" do
      sign_in(FactoryBot.create(:user, role: "organizer"))

      get admin_sponsor_qr_codes_path

      expected_code = SponsorVisitToken.generate(event_slug: event.slug, sponsor_key: "smartbank.co.jp")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sponsor QR Codes")
      expect(response.body).to include("SmartBank, Inc.")
      expect(response.body).to include(new_sponsor_passport_stamp_path(event.slug, code: expected_code))
      expect(response.body).to include("Stamp URL")
      expect(response.body).to include("Download PNG")
      expect(response.body).to include("Download all as ZIP")
      expect(response.body).to include('data-controller="sponsor-qr-codes"')
      expect(response.body).to include('data-sponsor-qr-codes-zip-filename-value="sponsor-qr-codes-2026.zip"')
      expect(response.body).to include('data-filename="sponsor-qr-smartbank.co.jp.png"')
      expect(response.body).not_to include("Coincheck, Inc.")
    end

    it "redirects a participant" do
      sign_in(FactoryBot.create(:user, role: "participant"))

      get admin_sponsor_qr_codes_path

      expect(response).to redirect_to(root_path)
    end

    it "redirects a logged-out user" do
      get admin_sponsor_qr_codes_path

      expect(response).to redirect_to(root_path)
    end
  end
end
