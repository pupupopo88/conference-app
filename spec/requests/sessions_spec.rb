require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /login" do
    let!(:event) { FactoryBot.create(:event, :make_ongoing) }

    it "passes an internal return location to both login forms" do
      return_to = "/sponsor_passports/2026/stamps/new?code=stamp-code"

      get login_path(return_to:)

      document = Nokogiri::HTML(response.body)
      github_form = document.at_css("#github-login-form")
      github_auth_uri = URI.parse(github_form["action"])
      expect(Rack::Utils.parse_query(github_auth_uri.query)["return_to"]).to eq(return_to)
      expect(document.at_css("form[action='/auth/email'] input[name='return_to']")["value"]).to eq(return_to)
    end

    it "does not pass an external return location to the login forms" do
      get login_path(return_to: "https://example.com/path")

      document = Nokogiri::HTML(response.body)
      github_form = document.at_css("#github-login-form")
      expect(github_form["action"]).to eq("/auth/github")
      expect(document.css("input[name='return_to']")).to be_empty
    end
  end

  describe "POST /auth/email (email and password authentication)" do
    let!(:operator) { FactoryBot.create(:user, role: :operator) }
    let!(:auth) {
      FactoryBot.create(
        :authentication_provider_email_and_password, user: operator, email: "sample@email.invalid", password: "password", password_confirmation: "password"
      )
    }

    context "given valid email and password" do
      it "should success to login" do
        post "/auth/email", params: {email: "sample@email.invalid", password: "password"}
        expect(response).to redirect_to(operators_path)
        expect(session[:user_id]).to eq operator.id
      end
    end

    context "given return_to param" do
      it "redirects to the internal return location after login" do
        post "/auth/email", params: {email: "sample@email.invalid", password: "password", return_to: "/2024/talks"}
        expect(response).to redirect_to("/2024/talks")
        expect(session[:user_id]).to eq operator.id
      end

      it "uses the default location when return_to is external" do
        post "/auth/email", params: {email: "sample@email.invalid", password: "password", return_to: "https://example.com/path"}

        expect(response).to redirect_to(operators_path)
      end
    end

    context "given email not exists" do
      it "should not success to login" do
        post "/auth/email", params: {email: "wrong@email.invalid", password: "password"}
        expect(response).to redirect_to(login_path)
        expect(session[:user_id]).to be_nil
      end
    end

    context "given password is wrong" do
      it "should not success to login" do
        post "/auth/email", params: {email: "sample@email.invalid", password: "p@ssw0rd"}
        expect(response).to redirect_to(login_path)
        expect(session[:user_id]).to be_nil
      end

      it "keeps an internal return location for another login attempt" do
        post "/auth/email", params: {
          email: "sample@email.invalid",
          password: "wrong-password",
          return_to: "/sponsor_passports/2026/stamps/new?code=stamp-code"
        }

        expect(response).to redirect_to(login_path(return_to: "/sponsor_passports/2026/stamps/new?code=stamp-code"))
      end
    end
  end

  describe "POST /auth/unknown (unknown provider)" do
    it "should not success to login" do
      post "/auth/unknown"
      expect(response).to redirect_to(login_path)
    end
  end

  describe "GET /logout" do
    let!(:user) { FactoryBot.create(:user) }
    before { sign_in(user) }

    it "should logout" do
      get "/logout"
      expect(response).to redirect_to(about_path)
      expect(session[:user_id]).to be_nil
    end
  end
end
