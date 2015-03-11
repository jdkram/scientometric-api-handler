require 'rake/testtask'
# http://learnrubythehardway.org/book/ex46.html

Rake::TestTask.new do |t|
  t.libs << "tests"
  t.test_files = FileList['tests/test*.rb']
  t.verbose = true
end
