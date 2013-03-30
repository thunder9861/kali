# Re-add our load path patch after bundler placed lib folder of "test-unit" gem before our usual loadpath patch
$:.unshift(ENV["RUBYMINE_TESTUNIT_REPORTER"])

# remove duplicates
$:.uniq!
