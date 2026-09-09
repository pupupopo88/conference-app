class SponsorCatalog
  REQUIRED_ATTRIBUTES = %i[key name plan logo].freeze
  LOGO_BASE_URL = "https://kaigionrails.org".freeze

  def self.for_year(year)
    sponsors = data_for(year).fetch(:sponsors)

    sponsors.each do |sponsor|
      missing_attributes = REQUIRED_ATTRIBUTES.reject { |attribute| sponsor[attribute].present? }
      raise KeyError, "Missing sponsor attributes: #{missing_attributes.join(", ")}" if missing_attributes.any?
    end

    duplicate_keys = sponsors.group_by { |sponsor| sponsor[:key] }.select { |_key, entries| entries.many? }.keys
    raise KeyError, "Duplicate sponsor keys: #{duplicate_keys.join(", ")}" if duplicate_keys.any?

    sponsors.map do |sponsor|
      labels = Array(sponsor[:labels]) #: Array[Hash[Symbol, untyped]]
      sponsor.merge(booth: labels.any? { |label| label[:type] == "booth" })
    end
  end

  def self.find(year, key)
    for_year(year).find { |sponsor| sponsor[:key] == key }
  end

  def self.with_booth(year)
    for_year(year).select { |sponsor| sponsor[:booth] == true }
  end

  def self.logo_url(year, sponsor)
    "#{LOGO_BASE_URL}/#{Integer(year)}/images/sponsors/#{sponsor.fetch(:logo)}.png"
  end

  def self.data_for(year)
    YAML.safe_load_file(
      Rails.root.join("db/seeds/#{Integer(year)}.yaml"),
      permitted_classes: [Symbol],
      aliases: false
    )
  end
  private_class_method :data_for
end
