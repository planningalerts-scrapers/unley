require "epathway_scraper"

scraper = EpathwayScraper.scrape_and_save(
  "https://online.unley.sa.gov.au/ePathway/Production",
  list_type: :last_30_days
)
