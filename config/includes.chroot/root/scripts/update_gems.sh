#!/bin/sh

# Updates all gems
# No arguments required

gem update -y --no-rdoc --no-ri
gem cleanup
sync

