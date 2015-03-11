# https://relishapp.com/vcr/vcr/v/2-9-3/docs/getting-started

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'vcr_cassettes'
  c.hook_into :webmock
end
