Dir["../lib/*.rb"].each {|file| require_relative file }

input = '../input/test.csv'
output = '../output/test.csv'
api = 'epmc'

# csv_create(input, output_csv: output, api: api)
get_altmetric('24668137', false)
