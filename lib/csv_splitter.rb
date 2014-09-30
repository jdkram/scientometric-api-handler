# CSV Splitter

require 'smarter_csv'

file_path = '../test/pmids/pmids20062013.csv'

chunked_pmids = SmarterCSV.process(file_path, {:chunk_size => 100})

chunked_pmids.each_with_index do |chunk, index|
  # Put each of them in its own CSVs
  CSV.open("../test/pmids/test#{"%03d" % index}.csv", 'w') do |csv| 
    csv << ['pmids']
    chunk.each do | entry |
      csv << [entry[:evidpmid][3..-1]]
    end
  end
end

# first_chunk = chunked_pmids[0]

# puts first_chunk[0][:evidpmid][3..-1]

# CSV.open('../test/pmids/test1.csv', 'w') do |csv| 
#    csv << ['pmids']
#   first_chunk.each do | entry |
#    csv << [entry[:evidpmid][3..-1]]
#   end
# end