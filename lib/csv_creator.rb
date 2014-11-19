require 'csv'

require_relative '../lib/api_caller'
# Number of requests per second
API_LIMITS = { altmetric: 2, epmc: 2, grist: 2, orcid: 2 }

# Convert API types to IDs
API_ID_TYPES = { altmetric: 'pmid', epmc: 'pmid', grist: 'grant_id', orcid: 'orcid_id' }

# Sample working IDs
SAMPLE_IDS = { altmetric: '24889601', epmc: '24889601', grist: '082178', orcid: '0000-0002-6435-1825' }

def time # Create time string for filenames
  Time.now.strftime('%Y%m%d_%H:%M')
end

def orcid_checksum(id) # http://d.pr/1jTbs
  id.gsub!(/-/, '')
  digits = id.split('')
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

def read_csv(input_csv)
  CSV.read(input_csv) # Add exceptions for invalid file
end

def csv_create(input_csv, output_csv: nil, api: nil)
  raise ArgumentError, "API not specified", caller[1..-1] if api.nil?
  raise ArgumentError, "Not a CSV file", caller[1..-1] unless input_csv =~ /\.csv/
  api = api.to_sym
  pause = 1.0 / API_LIMITS[api]
  output_csv ||= input_csv.sub(/.csv/, "_#{time}_output.csv")
  ids = read_csv(input_csv)
  i = 0
  bad_ids = []
  CSV.open(output_csv, 'w') do |csv|
    headers = call_api(SAMPLE_IDS[api], api).keys
    csv << headers
    ids.each do |id|
      unless check_id(id.first, api)  # Convert id from array to str
        bad_ids << id[0]
        next # Skip if they're bad
      end
      row = []
      call_api(id[0], api).each_value {|v| row << v }
      csv << row
      sleep pause
      i +=1
      if i % 5 == 0
        puts "#{i} / #{ids.length} complete. Approximately
      #{((ids.length - i) * pause).round} seconds remain"
      end
    end
  end
  # bad_ids.each { |bad_id| puts "Bad ID: #{bad_id.first}" }
end
