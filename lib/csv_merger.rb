# CSV Merger
# Let's merge all of those csvs we created

require 'csv'

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
  files.select! { |file| file =~ /altmetric_test[\d]{3}-2.csv/ }
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
end

# master = '../test/pmids/master_almetric2.csv'
# directory = '../test/pmids/'

# merge_csv(master, directory)