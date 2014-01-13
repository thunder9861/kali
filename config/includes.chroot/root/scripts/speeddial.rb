#!/usr/bin/ruby

# SpeedDial generator
# This script takes a yaml file with the format shown below and converts it
# into the json format required by the Chrome SpeedDial 2 extension.
# Works best with ruby 1.9.x series, because dictionaries are ordered.

# ---
# Group:
#    Dial_Title: Url
# ...

require 'singleton'
require 'ostruct'
require 'yaml'
require 'optparse'
require 'json'

# Bidirectional hash from here:
# http://stackoverflow.com/questions/6926270/bidirectional-hash-table-in-ruby
class BiHash

   def initialize
      @forward = Hash.new { |h, k| h[k] = [ ] }
      @reverse = Hash.new { |h, k| h[k] = [ ] }
   end

   def insert(k, v)
      @forward[k].push(v)
      @reverse[v].push(k)
      v
   end

   def fetch(k)
      fetch_from(@forward, k)
   end

   def rfetch(v)
      fetch_from(@reverse, v)
   end

   protected

   def fetch_from(h, k)
      return nil if(!h.has_key?(k))
      v = h[k]
      v.length == 1 ? v.first : v.dup
   end
end

# Defines an Id Manager
class IdManager
   include Singleton

   def initialize

      # Counters for the ids
      @group_id = 0
      @dial_id = 1

      # Mappings between the ids and the titles
      @group_map = BiHash.new
      @dial_map = BiHash.new

   end

   # Given a title, returns the associated group id
   def get_group_id(title)

      # Try to get an existing id
      id = @group_map.fetch(title)

      # If not available, make a new id associated with the title
      if id == nil
         id = @group_id
         @group_id += 1
         @group_map.insert(title, id)
      end

      return id

   end

   # Given a title, returns the associated dial id
   def get_dial_id(title)

      # Try to get an existing id
      id = @dial_map.fetch(title)

      # If not available, make a new id associated with the title
      if id == nil
         id = @dial_id
         @dial_id += 1
         @dial_map.insert(title, id)
      end

      return id

   end

   # Given an id, returns the associated group title, or nil if not found
   def get_group_title(id)

      # Try to get an existing title
      title = @group_map.rfetch(id)

      return title

   end

   # Given an id, returns the associated dial title, or nil if not found
   def get_dial_title(id)

      # Try to get an existing title
      title = @dial_map.rfetch(id)

      return title

   end

end

# Defines a group
class Group

   def initialize(title)
      @title = title
      @id = IdManager.instance.get_group_id(title)
      @dials = []
   end

   def id
      return @id
   end

   def add_dial(dial)
      dial.set_group_id(@id)
      @dials << dial
   end

   def get_dials
      return @dials
   end

   def to_json

      json = {}

      # Dynamic
      json['id'] = @id
      json['title'] = @title

      # Static
      json['color'] = 'FFFFFF'
      json['position'] = 99

      return json

   end

   def to_s
      return @title
   end

end

# Defines a dial
class Dial

   def initialize(title, url, thumbnail = '')
      @title = title
      @url = url
      @thumbnail = thumbnail || ''
      @id = IdManager.instance.get_dial_id(title)
   end

   def set_group_id(id)
      @group_id = id
   end

   def to_json

      json = {}

      # Dynamic
      json['id'] = @id
      json['title'] = @title
      json['url'] = @url
      json['thumbnail'] = @thumbnail
      json['idgroup'] = @group_id
      json['ts_created'] = Time.now.to_i

      # Static
      json['visits'] = 0
      json['visits_morning'] = 0
      json['visits_afternoon'] = 0
      json['visits_evening'] = 0
      json['visits_night'] = 0
      json['position'] = 999

      return json

   end

   def to_s
      return "%s: %s" % [@title, @url]
   end

end

# Default settings
class Settings

   def initialize
      @default_group_title = IdManager.instance.get_group_title(0)
   end

   def to_json

      json = {}

      # Dynamic
      json['options.defaultGroupName'] = @default_group_title

      # Static
      json['firstTime'] = 'false'
      json['options.alwaysNewTab'] = '0'
      json['options.apps.align'] = 'center'
      json['options.apps.iconsize'] = 'medium'
      json['options.apps.position'] = 'bottom'
      json['options.apps.show'] = '0'
      json['options.apps.theme'] = 'dark'
      json['options.background'] = 'http://farm6.static.flickr.com/5134/5565626330_a8ef933e18_o.jpg'
      json['options.backgroundPattern'] = 'http://farm6.static.flickr.com/5137/5565048757_357eda6018_o.jpg'
      json['options.backgroundPosition'] = 'center top'
      json['options.centerThumbnailsVertically'] = '1'
      json['options.centerVertically'] = '1'
      json['options.colors.bg'] = 'undefined'
      json['options.colors.border'] = 'CCCCCC'
      json['options.colors.borderover'] = '999999'
      json['options.colors.dialbg'] = 'FFFFFF'
      json['options.colors.dialbginner'] = 'FFFFFF'
      json['options.colors.dialbginnerover'] = 'FFFFFF'
      json['options.colors.dialbgover'] = 'FFFFFF'
      json['options.colors.title'] = '8C7E7E'
      json['options.colors.titleover'] = '333333'
      json['options.columns'] = '4'
      json['options.dialSpace'] = '95'
      json['options.dialspacing'] = '24'
      json['options.dialstyle.corners'] = '4'
      json['options.dialstyle.shadow'] = 'glow'
      json['options.dialstyle.titleposition'] = 'bottom'
      json['options.fontface'] = 'Helvetica,\"Helvetica Nueue\";arial,sans-serif'
      json['options.fontsize'] = '11'
      json['options.fontstyle'] = 'font-weight:normal;font-style:normal;'
      json['options.highlight'] = '0'
      json['options.order'] = 'position'
      json['options.padding'] = '4'
      json['options.refreshThumbnails'] = '0'
      json['options.repeatbackground'] = 'no-repeat'
      json['options.scrollLayout'] = '1'
      json['options.showAddButton'] = '0'
      json['options.showContextMenu'] = '0'
      json['options.showOptionsButton'] = '0'
      json['options.showTitle'] = '1'
      json['options.showVisits'] = '0'
      json['options.sidebar'] = '0'
      json['options.sidebaractivation'] = 'position'
      json['options.sidebar.showApps'] = '0'
      json['options.sidebar.showBookmarks'] = '0'
      json['options.sidebar.showBookmarksURL'] = '0'
      json['options.sidebar.showDelicious'] = '0'
      json['options.sidebar.showPinboard'] = '0'
      json['options.sidebar.showGooglebookmarks'] = '0'
      json['options.sidebar.showHistory'] = '0'
      json['options.thumbnailQuality'] = 'medium'
      json['options.titleAlign'] = 'center'
      json['options.useDeliciousShortcut'] = '0'
      json['refresh_create'] = 'false'
      json['refresh_id'] = ''
      json['refreshThumbnail'] = ''
      json['refresh_url'] = ''
      json['requestThumbnail'] = ''
#      json['sys.cellspacing'] = '24'
#      json['sys.cols'] = '4'
#      json['sys.containerwidth'] = '1512px'
#      json['sys.dialheight'] = '225.6'
#      json['sys.dialwidth'] = '360'
#      json['sys.rows'] = '2'
#      json['sys.rowspacing'] = '24'
      json['v1590'] = 'false'

      return json

   end

end

# Manages groups and dials
class SpeedDial

   def initialize
      @groups = []
   end

   def load_yaml(filename)

      # Load the yaml file
      y = YAML.load_file(filename)

      # For each group
      y.each do |group_title, dials|

         # Create a group object
         group = Group.new(group_title)

         # For each dial
         dials.each do |d|

            # Create a dial object
            dial_title = d.keys[0]
            url = d.values[0]
            thumbnail = get_thumbnail(url)

            dial = Dial.new(dial_title, url, thumbnail)

            # Add the dial to the group
            group.add_dial(dial)

         end

         # Add the group to the list
         @groups << group

      end

   end

   def get_thumbnail(url)
      return "http://api.webthumbnail.org/?width=500&height=400&screen=1024&url=" + url
      
   end
   
   def save_json(filename)

      # Set up the json dictionary
      json = {}
      json['groups'] = {}
      json['dials'] = {}
         
      # Get the default settings
      json['settings'] = Settings.new().to_json()
         
      count = 0
      
      # For each group
      groups.each do |g|
         
         # Do not add the default group to this list
         if g.id != 0
            
            # Add the group to the json output 
            json['groups'][count] = g.to_json
            count += 1
            
         end
         
      end

      count = 0
      
      # For each dial
      dials.each do |d|
         
         # Add the dial to the json output
         json['dials'][count] = d.to_json
         count += 1
         
      end
      
      # Generate the json
      s = JSON.pretty_generate(json)
      
      # Write the json fole
      File.open(filename, 'w'){|f| f.write(s)}
         
      return s

   end

   def groups
      return @groups
   end

   def dials

      dials = []
         
      # For each group
      @groups.each do |g|
         
         # Add the group's dials to the list
         dials += g.get_dials
         
      end

      return dials

   end

end

# Parse the command line options
options = OpenStruct.new
options.input = nil
options.output = nil

parser = OptionParser.new do |opts|

   opts.banner = "Usage: speeddial.rb --input <yaml> --output <json>"

   opts.on("-i", "--input YAML", "Input yaml file") do |i|
      options.input = i
   end

   opts.on("-o", "--output JSON", "Output json file") do |o|
      options.output = o
   end

   opts.on("-h", "--help", "Display usage information") do |h|
      puts opts
      exit
   end

end
parser.parse!

# Input file must exist
if options.input == nil or !File.exist?(options.input)
   puts "Must specify an existing input yaml file."
   exit
end

# Output file must be specified
if options.output == nil
   puts "Must specify an output json file."
   exit
end

sd = SpeedDial.new
sd.load_yaml(options.input)
sd.save_json(options.output)

