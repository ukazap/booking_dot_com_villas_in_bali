# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
require 'mechanize'
require 'uri'
require 'json'
require 'http'

data = []
agent = Mechanize.new
agent.user_agent_alias = 'Linux Firefox'
start_url = ENV['MORPH_START_URL']
api_key = ENV['MORPH_GOOGLE_MAP_API_KEY']

page = agent.get(place_url)

loop do
  page.search(".sr_item.sr_item_new").each do |item|
    hotel_name_link = item.at_css('.hotel_name_link.url')
    hotel_name = hotel_name_link.at_css('.sr-hotel__name').text.strip
    hotel_coordinate = item.at_css('.bui-link').attr('data-coords').strip.split(',').reverse.join(',')

    request = HTTP.get("https://maps.googleapis.com/maps/api/place/findplacefromtext/json", :params => {
      input: hotel_name,
      key: api_key,
      inputtype: 'textquery'
    }).parse['candidates']&.first.try('place_id')



    contancts = HTTP.get('https://maps.googleapis.com/maps/api/place/details/json', :params => {
      key: api_key,
      place_id: hotel_id,
      fields: 'international_phone_number,formatted_phone_number,website'
    }).parse['result']

    data = {
      'href' => hotel_name_link[:href].gsub(/\.en-gb.+/, ''),
      'name' => hotel_name,
      'coordinates' => hotel_coordinate,
      'address' => item.at_css('.bui-link > text()').to_s.strip,
      'review_score' => item['data-score']
    }.merge!(contancts)

    puts "add #{data['name']}"
    ScraperWiki.save_sqlite(['name', 'coordinates'], data)
  end

  next_button = page.link_with(css: '.bui-pagination__link.paging-next')
  break if next_button.nil?
  page = next_button.click
  puts "next page"
end

puts "done"
