require "rails_helper"

RSpec.describe SponsorVisitProgress do
  describe "milestones" do
    it "reports the current milestone and distance to the next one" do
      progress = described_class.new(visited_count: 7, total_count: 22)

      expect(progress.current_milestone).to eq(count: 5, key: :hello_sponsors)
      expect(progress.next_milestone).to eq(count: 12, key: :halfway)
      expect(progress.remaining_to_next).to eq(5)
      expect(progress.milestones).to eq([
        {count: 5, key: :hello_sponsors},
        {count: 12, key: :halfway},
        {count: 22, key: :complete}
      ])
      expect(progress).not_to be_completed
    end

    it "points a new participant to the first milestone" do
      progress = described_class.new(visited_count: 0, total_count: 22)

      expect(progress.current_milestone).to be_nil
      expect(progress.next_milestone).to eq(count: 5, key: :hello_sponsors)
      expect(progress.remaining_to_next).to eq(5)
    end

    it "has only the completion milestone for a single booth" do
      progress = described_class.new(visited_count: 0, total_count: 1)

      expect(progress.milestones).to eq([{count: 1, key: :complete}])
      expect(progress.percentage).to eq(0)
      expect(progress.percentage(1)).to eq(100)
    end

    it "handles an event without booths without dividing by zero" do
      progress = described_class.new(visited_count: 0, total_count: 0)

      expect(progress.percentage).to eq(0)
      expect(progress.next_milestone).to be_nil
      expect(progress).to be_completed
    end

    it "reports completion using the supplied sponsor total" do
      progress = described_class.new(visited_count: 22, total_count: 22)

      expect(progress.current_milestone).to eq(count: 22, key: :complete)
      expect(progress.next_milestone).to be_nil
      expect(progress.remaining_to_next).to be_nil
      expect(progress).to be_completed
    end
  end
end
