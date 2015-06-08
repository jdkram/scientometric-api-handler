Dir["../lib/*.rb"].each {|file| require_relative file }

input = '../input/kiri_fundref.csv'
output = '../output/kiri_fundref.csv'
api = 'epmc'

# csv_create(input, output_csv: output, api: api)
csv_create(input, output_csv: output, api: api)
# get_altmetric('24668137', false)
