require 'require_all'

require_all 'lib'

input = './input/PubMed_1000_original.csv'
output = './output/PubMed_1000_original_altmetric.csv'
api = 'altmetric'

csv_create(input, output_csv: output, api: api)

