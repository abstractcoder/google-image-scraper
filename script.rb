#!/usr/bin/env ruby

require 'bundler'
Bundler.require
require 'cgi'
require 'open-uri'
require 'fileutils'
require 'rack/mime'
require 'base64'

images_folder = ENV['HOME'] + "/Downloads/images/"
search = ARGV.join(" ")
folder = images_folder + search + "/"

driver = Selenium::WebDriver.for(:chrome)
driver.navigate.to "https://images.google.com/"
element = driver.find_element(:name, 'q')
element.send_keys search
element.submit

elements = driver.find_elements(:css, '[href^="/imgres"]')
urls = elements.map{|e| URI(e.attribute(:href))}
image_urls = urls.map{|url| CGI.parse(url.query)["imgurl"]}.flatten

threads = image_urls.map do |image_url|
  Thread.new {
    begin
      puts image_url
  
      open(image_url, read_timeout: 5) do |image|
        FileUtils.mkdir_p folder
    
        filename = Base64.urlsafe_encode64(image_url, padding: false)
        ext = Rack::Mime::MIME_TYPES.invert[image.content_type]
    
        File.open(folder + filename + ext, "wb") do |file|
          file.write(image.read)
        end
      end
    rescue => e
      
    end
  }
end

threads.each(&:join)

driver.quit


