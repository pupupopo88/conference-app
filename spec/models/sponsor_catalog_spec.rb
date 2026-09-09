require "rails_helper"

RSpec.describe SponsorCatalog do
  describe ".for_year" do
    subject(:sponsors) { described_class.for_year(2026) }

    it "loads the sponsors for the year" do
      expect(sponsors.size).to eq(55)
    end

    it "provides the required attributes for every sponsor" do
      expect(sponsors).to all(include(:key, :name, :plan, :logo, :booth))
      expect(sponsors.pluck(:key)).to contain_exactly(*sponsors.pluck(:key).uniq)
      expect(sponsors).to all(satisfy { |sponsor| !sponsor.key?(:url) && !sponsor.key?(:profile) })
    end

    it "keeps sponsors without a booth available" do
      expect(sponsors).to include(include(key: "coincheck.com", booth: false))
      expect(sponsors).to include(include(key: "lovegraph.me", booth: false))
    end

    it "keeps labels from the sponsor master" do
      mov = sponsors.find { |sponsor| sponsor[:key] == "mov.am" }

      expect(mov[:labels]).to include(name: "Print sticker sponsor", type: "custom")
    end
  end

  describe ".find" do
    it "finds a sponsor by its stable key" do
      expect(described_class.find(2026, "smartbank.co.jp")).to include(
        key: "smartbank.co.jp",
        name: "SmartBank, Inc.",
        plan: "gold",
        logo: "S313_smartbank.co.jp_gold",
        booth: true
      )
    end
  end

  describe ".logo_url" do
    it "builds the official site URL from the year and logo identifier" do
      sponsor = described_class.find(2026, "mov.am")

      expect(described_class.logo_url(2026, sponsor)).to eq(
        "https://kaigionrails.org/2026/images/sponsors/S309_mov.am_ruby.png"
      )
    end
  end

  describe ".with_booth" do
    subject(:sponsors) { described_class.with_booth(2026) }

    it "returns only sponsors with a booth" do
      expect(sponsors.size).to eq(22)
      expect(sponsors).to all(include(booth: true))
      expect(sponsors.pluck(:key)).to include("smartbank.co.jp")
      expect(sponsors.pluck(:key)).not_to include("coincheck.com")
    end
  end
end
