# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
require 'mechanize'
require 'http'

data = []
agent = Mechanize.new
agent.user_agent_alias = 'Linux Firefox'
api_key = ENV['MORPH_GOOGLE_MAPS_API_KEY']&.strip

start_urls = ENV['MORPH_START_URLS'].lines.map(&:strip)

start_urls.each do |start_url|
  page = agent.get(start_url)

  loop do
    page.search(".sr_item.sr_item_new").each do |item|
      hotel_name_link = item.at_css('.hotel_name_link.url')
      hotel_name = hotel_name_link.at_css('.sr-hotel__name').text.strip
      hotel_coordinates = item.at_css('.bui-link').attr('data-coords').strip.split(',').reverse.join(',')

      request = HTTP.get("https://maps.googleapis.com/maps/api/place/findplacefromtext/json", params: {
        input: hotel_name,
        key: api_key,
        inputtype: 'textquery',
        locationbias: "point:#{hotel_coordinates}"
      })

      place_id = request.parse["candidates"].first["place_id"] rescue nil
      contact_info = {}

      if !place_id.nil?
        contact_info = HTTP.get('https://maps.googleapis.com/maps/api/place/details/json', params: {
          key: api_key,
          place_id: place_id,
          fields: 'international_phone_number,website'
        }).parse['result'] || {}
      end

      data = {
        'href' => hotel_name_link[:href].split(".en-gb")[0].strip,
        'name' => hotel_name,
        'coordinates' => hotel_coordinates,
        'address' => item.at_css('.bui-link > text()').to_s.strip,
        'review_score' => item['data-score'],
        'phone_number' => contact_info['international_phone_number'],
        'website' => contact_info['website']
      }

      print "."
      ScraperWiki.save_sqlite(['name', 'coordinates'], data)
    end

    next_button = page.link_with(css: '.bui-pagination__link.paging-next')
    break if next_button.nil?
    page = next_button.click
    puts "next page"
  end

  puts "done"
end
