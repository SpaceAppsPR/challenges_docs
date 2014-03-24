# gem install nokogiri
# install pandoc - http://johnmacfarlane.net/pandoc/installing.HTML
# gem install pandoc-ruby

require 'nokogiri'
require 'open-uri'
require 'pandoc-ruby'
require 'json'

category_hashes = JSON.parse(File.open('space.json').read) rescue nil
if !category_hashes
  base_uri = "https://2014.spaceappschallenge.org/"
  category_links = Nokogiri::HTML(open("#{base_uri}/challenge")).css('#category_array a').map {|l| l.attributes['href'].text}
  categories = category_links.map {|cat| cat.split('/').last}
  category_hashes = {}
  category_links.each_with_index do |link, index|
    category = categories[index]
    challenge_links = Nokogiri::HTML(open("#{base_uri}#{link}")).css('#challenge_array a').map {|l| l.attributes['href'].text}
    category_hashes.merge!({category => {links: challenge_links} })
    category_challenges = []
    challenge_links.each do |challenge_link|
      challange_html = Nokogiri::HTML(open("#{base_uri}#{challenge_link}"))
      challenge_name = challange_html.at_css('h2').text
      challenge_text = challange_html.at_css('#descriptionTab').inner_html
      category_challenges << {challenge_name => challenge_text}
    end
    category_hashes[category][:challenges]=category_challenges
  end
end


category_hashes.each do |category, data|
  Dir.mkdir(File.join(Dir.pwd, "#{category}"))
  directory = File.join(Dir.pwd, "#{category}")
  data['challenges'].each do |challenge|
    challenge_name =  challenge.keys.first
    html = challenge.values
    conversion = PandocRuby.convert(html, :from => :html, :to => :docx)
    File.open("#{directory}/#{challenge_name}.docx", "wb") {|f| f.write conversion}
  end
end