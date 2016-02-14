require 'nokogiri'
require 'open-uri'
require 'json'
require 'require_all'

require_relative '../config'
require_all 'lib' # Require everything in current directory

BASEURLS = {
  altmetric: "http://api.altmetric.com/v1/ID_TYPE/QUERY#{ALTMETRIC_API_KEY}",
  epmc: "http://www.ebi.ac.uk/europepmc/webservices/rest/search/query=EXT_ID:QUERY&resulttype=core",
  grist: "http://plus.europepmc.org/GristAPI/rest/get/query=gid:QUERY&resulttype=core",
  orcid: "http://pub.orcid.org/v1.1/QUERY/orcid-profile"
}

def create_url(identifier, type)
  url = BASEURLS[type].sub(/QUERY/, identifier)
  id_type = classify_id(identifier)
  return url.sub(/ID_TYPE/, id_type)
end

def classify_id(identifier)
  if identifier =~ /\// # If ID contains a slash, it's a DOI
    return 'doi'  
  elsif identifier =~ /\d{4,8}/
    return 'pmid'
  elsif identifier =~ /\d{4}-\d{4}-\d{4}-\d{3}(\d|X)/
    return 'orcid'
  else
    return 'unknown_id'
  end
end

def call_api(id, api, raw: false)
  api = api.to_sym
  case api
  when :epmc
    get_epmc(id, raw)
  when :altmetric
    get_altmetric(id, raw)
  when :orcid
    get_orcid(id, raw)
  else
    raise ArgumentError, "Not a valid API"
  end
end

