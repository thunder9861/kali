#!/bin/sh

# Updates all gems
# No arguments required

gem1.9.2 update -y --no-rdoc --no-ri
gem1.9.2 cleanup
gem1.8 update -y --no-rdoc --no-ri
gem1.8 cleanup
rm -rf ~/ruby/1.9.2/doc/*
rm -rf /usr/lib/ruby/gems/1.8/doc/*
rm -rf /usr/lib/ruby/gems/1.9.2/doc/*
sync

