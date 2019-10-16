# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
require 'mechanize'

data = []
agent = Mechanize.new
agent.user_agent_alias = 'Linux Firefox'
start_url = "https://www.booking.com/searchresults.en-gb.html?aid=304142&label=gen173nr-1FCAEoggI46AdIM1gEaGiIAQGYAQm4AQfIAQzYAQHoAQH4AQuIAgGoAgO4Auv1le0FwAIB&sid=1876e63eb536b37149c5db2c76040480&tmpl=searchresults&ac_click_type=b&ac_position=0&class_interval=1&clear_ht_id=1&dest_id=835&dest_type=region&from_sf=1&group_adults=2&group_children=0&label_click=undef&nflt=ht_id%3D213%3B&no_rooms=1&percent_htype_hotel=1&raw_dest_type=region&room1=A%2CA&sb_price_type=total&search_selected=1&shw_aparth=1&slp_r_match=0&src=index&srpvid=c3523cc0b5a4008b&ss=Bali%2C%20Indonesia&ss_raw=Bali&ssb=empty&top_ufis=1&rows=25"

page = agent.get(start_url)

loop do
  page.search(".sr_item.sr_item_new").each do |item|
    hotel_name_link = item.at_css('.hotel_name_link.url')

    data = {
      'href' => hotel_name_link[:href].strip,
      'name' => hotel_name_link.at_css('.sr-hotel__name').text.strip,
      'coordinates' => item.at_css('.bui-link').attr('data-coords').strip,
      'address' => item.at_css('.bui-link > text()').to_s.strip,
      'review_score' => item['data-score']
    }
    
    puts "add #{data['name']}"
    ScraperWiki.save_sqlite(['href'], data)
  end
  
  next_button = page.link_with(css: '.bui-pagination__link.paging-next')
  break if next_button.nil?
  next_button.click
end

puts "done"