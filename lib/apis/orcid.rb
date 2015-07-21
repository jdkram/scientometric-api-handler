require 'nokogiri'
require 'open-uri'
require 'json'

ORCID_ATTRIBUTES = {
  id: '//path',
  creation_method: '//creation-method',
  submission_date: '//submission-date',
  last_modified_date: '//last-modified-date',
  claimed: '//claimed',
  given_names: '//given-names',
  family_name: '//family-name',
  credit_name: '//credit-name',
  other_name: '//other_name',
}

def get_orcid(id, raw)
  url = create_url(id, :orcid)
  article = {}
  orcid_xml = Nokogiri::HTML(open(url))
  ORCID_ATTRIBUTES.each do |key,value| # USE THIS STRUCTURE FOR OTHERS
    if orcid_xml.at_xpath(value)
     article[key] = orcid_xml.at_xpath(value).content
    else
      article[key] = nil
    end
  end
  article[:works_count] = orcid_xml.xpath('//orcid-work').length
  article[:STATUS] = "SUCCESS at #{Time.now}"
  return article
   
   rescue OpenURI::HTTPError => e
    if e.message == '404 Not Found'
      ORCID_ATTRIBUTES.each do |key, value| 
        article[key] = nil
      end
      article[:works_count] = nil
      article[:STATUS] = "NO ENTRY at #{Time.now}"
      return article
    else
      raise e
    end

    rescue Errno::ETIMEDOUT => e
      ORCID_ATTRIBUTES.each do |key, value| 
        article[key] = nil
      end
      article[:works_count] = nil
      article[:STATUS] = "TIMEOUT at #{Time.now}"
      return article
end