
# Convert API types to IDs
API_ID_TYPES = { altmetric: 'pmid', epmc: 'pmid', grist: 'grant_id', orcid: 'orcid_id' }


def orcid_checksum(id) # http://d.pr/1jTbs
  orcid_id = id.gsub(/-/, '') # Can't gsub the id as this gets used later
  digits = orcid_id.split('')
  checksum = digits.pop
  total = 0
  digits.each do |d|
    total = (d.to_i + total) * 2
  end
  remainder = total % 11
  result = (12 - remainder) % 11
  calculated_checksum = (result == 10) ? 'X' : result.to_s
  calculated_checksum == checksum
end

def check_id(id, api) # Check to see if IDs are valid
  type = API_ID_TYPES[api.to_sym]
  case type
  when 'pmid'
    !!(id =~ /^\d{1,8}$/)
  when 'grant_id'
    !!true # Need a spec for grant_ids
  when 'orcid_id'
    !!(id =~ /\d{4}-\d{4}-\d{4}-\d{3}(\d|X)/ && orcid_checksum(id))
  end
end
