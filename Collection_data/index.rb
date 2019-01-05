require 'logger'
require 'nokogiri'
require 'curb'
require 'csv'

# id = pagination_bottom
def get_number_of_pages(doc)
  doc.xpath("//div[@id='pagination_bottom']/ul/li/a/span/text()")[-2].to_s.to_i
end


# class = product-container/a.href
def get_all_items(url)
  xpath_of_items_href = "//div[@class = 'product-container']//a[@class = 'product_img_link product-list-category-img']/@href"
  items = []
  number_of_pages = get_number_of_pages(Nokogiri::HTML(Curl.get(url).body()))

  all_urls = (1..number_of_pages).map{ |i|  url + "?p=" + i.to_s}
  p = 0
  Curl::Multi.get(all_urls) do |html|
    items += Nokogiri::HTML(html.body()).xpath(xpath_of_items_href)
  end
  items
end



def get_data(doc, file_name)
  doc = Nokogiri::HTML(doc)

  name_ = doc.xpath('//h1[@class = "product_main_name"]/text()').to_s.strip
  img_url = doc.xpath("//div[@id = 'image-block']//img/@src")
  prices = doc.xpath("//span[@class = 'price_comb']/text()")
  weight = doc.xpath("//span[@class = 'radio_label']/text()")
  count = weight.size()

  CSV.open("#{file_name}.csv", "ab") do |csv|
    for i in (0...count)
      price = prices[i].to_s.split[0]
      csv << ["#{name_} - #{weight[i]}", price, img_url ]
    end
  end

end


if ARGV[0] && ARGV[1]
  FILE_NAME = ARGV[0]
  URL = ARGV[1]
  logger = Logger.new(STDOUT)
  logger.level = Logger::INFO

  logger.info("Program started")

  logger.info("Getting all item urls")
  all_items = get_all_items(URL)

  logger.info("Getting an information and writing to the csv")
  CSV.open("#{FILE_NAME}.csv", "wb") do |csv|
      csv << ["Name", "Price (€)", "Image"]
    end

  Curl::Multi.get(all_items) do |html|
    get_data(html.body(), FILE_NAME)
  end

  logger.info("Parsed successfully")

else
  logger.info("Invalid input")
end