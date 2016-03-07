require 'csv'
require 'smarter_csv'
require 'colorize'

require_relative '../lib/api_handler'
require_relative '../lib/id_checker'

# Take an input CSV
# Create a working directory for it, split it up



def split_csv(csv, chunk_size=100)
  # Create a folder to put the split CSVs in
  filename = File.basename(csv, ".csv")
  # Without the :row_sep => :auto it wouldn't accept simple csvs 
  chunked_pmids = SmarterCSV.process(csv, {:chunk_size => chunk_size, :row_sep => :auto})
  subfolder = File.join(File.dirname(csv), filename + "_SPLIT")
  Dir.mkdir(subfolder) unless File.exists?(subfolder)
  Dir.chdir(subfolder) do
    # puts Dir.getwd
    chunked_pmids.each_with_index do |chunk, index|
      # Put each of them in its own CSVs
      CSV.open("#{filename}_#{"%03d" % index}.csv", 'w') do |csv| 
        csv << ['pmids']
        chunk.each { |entry| csv << entry.each_value }
      end
    end
  end
  return subfolder
end

# files = Dir.entries(directory)

# files.select! { |file| file =~ /altmetric_test[\d]{3}.csv/ }
# files.map! { |file| file = directory + file}
# files.map! { |file| file.encode("utf-8")}
# File.open('../test/pmids/altmetric_test000.csv', "r:utf-8") { |file| puts file.read }

# files = ['../test/pmids/altmetric_test000.csv','../test/pmids/altmetric_test001.csv']
def merge_csv(master, directory)
  files = Dir.entries(directory)
  # Need to generalise this next line rather than having to go back
  #   and edit
  files.select! { |file| file =~ /\w+[\d]{3}_output.csv/ }
  files.map! { |file| file = directory + file}
  CSV.open(master,'w') do |csv|
    # Grab the header row
    csv << CSV.read(files.first, encoding: 'utf-8')[0] 
    files.each do |file|
      inputcsv = CSV.read(file,encoding: 'utf-8')
      inputcsv.shift # Pop headers off
      inputcsv.each do |line|
        csv << line # Add each line to the master
      end
    end
  end
  puts "Merged files in #{directory} to #{master}".colorize(:green)
end

# master = '../test/pmids/master_almetric2.csv'
# directory = '../test/pmids/'

# Number of requests per second
API_LIMITS = { altmetric: 1, epmc: 10, grist: 2, orcid: 2 }

# Sample working IDs
SAMPLE_IDS = { 
  altmetric: '24889601',
  epmc: '24889601',
  grist: '082178',
  orcid: '0000-0002-6435-1825' 
}

def date # Create time string for filenames
  # Time.now.strftime('%Y%m%d_%H%M')
  Time.now.strftime('%Y%m%d')
end

def read_csv(input_csv)
  CSV.read(input_csv) # Add exceptions for invalid file
end


# Better name than csv_create? That's kind of a side effect
#   process_batch? batch_query_api?
def csv_create(input_csv, output_csv: nil, api: nil)
  raise ArgumentError, "API not specified", caller[1..-1] if api.nil?
  raise ArgumentError, "Not a CSV file", caller[1..-1] unless input_csv =~ /\.csv/
  begin
  api = api.to_sym
  pause = 1.0 / API_LIMITS[api]
  output_csv ||= input_csv.sub(/.csv/, "_output.csv")
  ids = read_csv(input_csv)
  bad_ids = []
    CSV.open(output_csv, 'w') do |csv|
      # Use a sample known ID to create headers
      headers = call_api(SAMPLE_IDS[api], api).keys
      csv << headers
      ids.shift unless check_id(ids[0], api) # Remove 'pmids' header
      ids.each_with_index do |id, i|
        unless check_id(id.first, api)  # Convert id from arr to str
          bad_ids << id[0]
          # puts "Skipping invalid ID: #{id[0]}"
          next # Skip if they're bad
        end
        row = []
        call_api(id[0], api).each_value {|v| row << v }
        csv << row
        sleep pause
        if i == 0 || (i % 25 == 0 && i != ids.length)
          # 0.38 is the average time to get a response from EPMC, write to CSV
          # Should pull in average API response times to this
          puts "  #{i} / #{ids.length} complete. ~#{((ids.length - i) * (0.38 + pause)).round} seconds remain"
        end
      end
    end
      rescue Interrupt => i
      File.delete(output_csv)
      puts "\n✘ Deleted partial output CSV: #{output_csv}\n".colorize(:red)
      raise Interrupt, "User terminated run."
      rescue OpenURI::HTTPError => e
      if e.message == '502 Proxy Error'
      puts "\n✘ Connection dropped, deleted partial output CSV: #{output_csv}\n".colorize(:red)
      else
        raise e
      end
  end
  puts "Invalid IDs: #{bad_ids}" unless bad_ids.length == 0
end


# Go over each of the split CSVs, generate an output CSV
def process_split_csvs(split_csv_directory, api)
  files = Dir.entries(split_csv_directory)
  files.select! { |file| file =~ /\w+[\d]{3}.csv/ }
  puts "Processing #{files[0..3]} and #{files.length-4} more via #{api}"
  files.each do |file|
    output_file = file.sub(/.csv/, "_output.csv")
      output_file_full_name = split_csv_directory + '/' + output_file
      input_file_full_name = split_csv_directory + '/' + file
      if File.file?(output_file_full_name)
        puts "#{output_file} already created, skipping...".colorize(:yellow)
      else
        puts "Processing #{file}..."
        # create full paths
        csv_create(input_file_full_name, output_csv: output_file_full_name, api: api)
        puts "#{file} completed, output saved to #{output_file}".colorize(:green)
      end
    end
end
