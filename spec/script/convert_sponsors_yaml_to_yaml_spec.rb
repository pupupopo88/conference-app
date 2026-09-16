require "spec_helper"
require "fileutils"
require "open3"
require "tmpdir"
require "yaml"

RSpec.describe "sponsor data conversion" do
  around do |example|
    Dir.mktmpdir do |directory|
      @project_root = directory
      FileUtils.mkdir_p(File.join(directory, "script"))
      FileUtils.cp(File.expand_path("../../script/convert_sponsors_yaml_to_yaml.rb", __dir__), File.join(directory, "script"))
      example.run
    end
  end

  def write_input(name, content)
    File.write(File.join(@project_root, name), content)
  end

  def convert_sponsors
    Open3.capture3(RbConfig.ruby, File.join(@project_root, "script/convert_sponsors_yaml_to_yaml.rb"), "2026")
  end

  def output_path
    File.join(@project_root, "data/sponsors/2026.yaml")
  end

  def output_data
    YAML.safe_load_file(output_path, permitted_classes: [Symbol])
  end

  before do
    write_input("sponsors.yml", <<~YAML)
      tiers:
      - slug: ruby
        name: Ruby Sponsors
        sponsors:
        - name: " Example Inc. "
          url: https://www.example.com/
          logo: S123_example.com_ruby
          profile: An example sponsor
          labels:
          - name: Print sticker sponsor
            type: custom
          - name: Booth
            type: booth
      - slug: silver
        name: Silver Sponsors
        sponsors:
        - name: Another Inc.
          logo: S456_another.example_silver
    YAML
  end

  it "converts sponsor tiers and labels" do
    _stdout, stderr, status = convert_sponsors

    expect(status.success?).to be(true), stderr
    expect(output_data.fetch(:sponsors)).to eq([
      {key: "example.com", name: "Example Inc.", plan: "ruby", logo: "S123_example.com_ruby", labels: [
        {name: "Print sticker sponsor", type: "custom"},
        {name: "Booth", type: "booth"}
      ]},
      {key: "another.example", name: "Another Inc.", plan: "silver", logo: "S456_another.example_silver"}
    ])
  end

  it "preserves sponsor information and its source when rerunning sponsor conversion" do
    source = File.read(File.join(@project_root, "sponsors.yml"))
    _stdout, stderr, status = convert_sponsors
    expect(status.success?).to be(true), stderr
    sponsors = output_data.fetch(:sponsors)

    _stdout, stderr, status = convert_sponsors

    expect(status.success?).to be(true), stderr
    expect(output_data.fetch(:sponsors)).to eq(sponsors)
    expect(File.read(File.join(@project_root, "sponsors.yml"))).to eq(source)
  end

  it "fails without writing output when sponsors.yml is missing" do
    File.delete(File.join(@project_root, "sponsors.yml"))

    _stdout, stderr, status = convert_sponsors

    expect(status.success?).to be(false)
    expect(stderr).to include("sponsors.yml not found")
    expect(File.exist?(output_path)).to be(false)
  end

  it "rejects malformed logos before overwriting existing sponsor data" do
    source = File.read(File.join(@project_root, "sponsors.yml"))
    write_input("sponsors.yml", source.sub("S123_example.com_ruby", "invalid_logo"))
    FileUtils.mkdir_p(File.dirname(output_path))
    File.write(output_path, "existing sponsor data")

    _stdout, stderr, status = convert_sponsors

    expect(status.success?).to be(false)
    expect(stderr).to include("Invalid sponsor logo", "invalid_logo")
    expect(File.read(output_path)).to eq("existing sponsor data")
  end

  it "does not overwrite existing database seed files" do
    seed_path = File.join(@project_root, "db/seeds/2026.yaml")
    FileUtils.mkdir_p(File.dirname(seed_path))
    seed_content = YAML.dump({talks: [{title: "Existing talk"}]})
    File.write(seed_path, seed_content)

    _stdout, stderr, status = convert_sponsors

    expect(status.success?).to be(true), stderr
    expect(File.read(seed_path)).to eq(seed_content)
  end

  it "rejects duplicate sponsor keys across tiers" do
    source = File.read(File.join(@project_root, "sponsors.yml"))
    write_input("sponsors.yml", source.sub("S456_another.example_silver", "S456_example.com_silver"))

    _stdout, stderr, status = convert_sponsors

    expect(status.success?).to be(false)
    expect(stderr).to include("Duplicate sponsor keys: example.com")
    expect(File.exist?(output_path)).to be(false)
  end
end
