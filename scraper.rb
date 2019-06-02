require "epathway_scraper"

base_url = "https://online.unley.sa.gov.au/ePathway/Production/Web/GeneralEnquiry/"
url = "#{base_url}enquirylists.aspx"

scraper = EpathwayScraper::Scraper.new(
  "https://online.unley.sa.gov.au/ePathway/Production"
)

agent = Mechanize.new

p "Getting first page"
first_page = agent.get url
url_query = url + '?' + first_page.body.scan(/js=-?\d+/)[0]  # enable JavaScript
first_page = agent.get url_query

p "Selecting List of Development Applications and clicking Next"
first_page_form = first_page.forms.first
first_page_form.radiobuttons[0].click
search_page = first_page_form.click_button

p "Clicking Date Lodged"
search_form = search_page.forms.first
search_form['__EVENTTARGET'] = 'ctl00$MainBodyContent$mGeneralEnquirySearchControl$mTabControl$tabControlMenu'
search_form['__EVENTARGUMENT'] = '3'
search_page = agent.submit(search_form)

p "Searching"
search_form = search_page.forms.first
# get the button you want from the form
button = search_form.button_with(:value => "Search")
# submit the form using that button
summary_page = agent.submit(search_form, button)

count = 0
while summary_page
  EpathwayScraper::Page::Index.scrape_index_page(summary_page, scraper.base_url, scraper.agent) do |record|
    EpathwayScraper.save(record)
  end

  next_page_img = summary_page.root.at_xpath("//td/input[contains(@src, 'nextPage')]")
  summary_page = nil
  if next_page_img
    count += 1
    if count > 50  # safety precaution
      p "Stopping paging after " + count.to_s + " pages."
      break
    end
    next_page_path = next_page_img['onclick'].split(',').find { |e| e =~ /.*PageNumber=\d+.*/ }.gsub('"', '').strip
    p "Next page: " + next_page_path
    summary_page = agent.get "#{base_url}#{next_page_path}"
  end
end
