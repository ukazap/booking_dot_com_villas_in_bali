# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
require 'mechanize'

data = []
agent = Mechanize.new
agent.user_agent_alias = 'Linux Firefox'
start_url = ENV['MORPH_START_URL']

page = agent.get(start_url)

loop do
  page.search(".sr_item.sr_item_new").each do |item|
    hotel_name_link = item.at_css('.hotel_name_link.url')

    data = {
      'href' => hotel_name_link[:href].strip.gsub(/\?.+/, ''),
      'name' => hotel_name_link.at_css('.sr-hotel__name').text.strip,
      'coordinates' => item.at_css('.bui-link').attr('data-coords').strip.split(',').reverse.join(','),
      'address' => item.at_css('.bui-link > text()').to_s.strip,
      'review_score' => item['data-score']
    }

    puts "add #{data['name']}"
    ScraperWiki.save_sqlite(['name', 'coordinates'], data)
  end

  next_button = page.link_with(css: '.bui-pagination__link.paging-next')
  break if next_button.nil?
  page = next_button.click
  puts "next page"
end

puts "done"
