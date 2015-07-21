require 'csv'

require_relative '../lib/api_caller'
require_relative '../lib/id_checker'
# Number of requests per second
API_LIMITS = { altmetric: 1, epmc: 2, grist: 2, orcid: 2 }

# Sample working IDs
SAMPLE_IDS = { 
  altmetric: '24889601',
  epmc: '24889601',
  grist: '082178',
  orcid: '0000-0002-6435-1825' 
}

def time # Create time string for filenames
  Time.now.strftime('%Y%m%d_%H%M')
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
      unless check_id(id.first, api)  # Convert id from arr to str
        bad_ids << id[0]
        next # Skip if they're bad
      end
      row = []
      call_api(id[0], api).each_value {|v| row << v }
      csv << row
      sleep pause
      i +=1
      if i % 5 == 0
        puts "#{i} / #{ids.length} complete. ~#{((ids.length - i) * pause).round + 3} seconds remain"
      end
    end
  end
  # bad_ids.each { |bad_id| puts "Bad ID: #{bad_id}" }
end
