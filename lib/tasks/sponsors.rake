namespace :sponsors do
  desc "Print sponsor stamp URLs for an event year"
  task :stamp_urls, [:year] => :environment do |_task, args|
    year = args.fetch(:year)

    SponsorCatalog.with_booth(year).each do |sponsor|
      url = SponsorVisitToken.stamp_url(event_slug: year, sponsor_key: sponsor.fetch(:key))
      puts "#{sponsor.fetch(:name)}\t#{url}"
    end
  end
end
