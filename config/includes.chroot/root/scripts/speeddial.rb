#!/usr/bin/ruby

require 'rubygems'
require 'open-uri'
require 'json'
require 'ipaddr'
require 'resolv'
require 'trollop'
require 'yaml'
require 'uri'

class SpeedDial

   def initialize
   
      @group_id = 0
      @dial_id = 0
      @group_to_id = {}
      @first_group = nil
      
      # Actual output data
      @group_hash = {}
      @dial_hash = {}

   end

   def parse(yaml_object)
   
      yaml_object.each do |group, entries|
         begin
            entries.each do |h|
            
               title = h.keys[0]
               url = h.values[0]
               add_dial(group, title, url)
            
            end
         rescue Exception => e
            puts e
         end
      
      end
      
   end
   
   def groups
      
      return @group_hash
      
   end
   
   def dials
      
      return @dial_hash
      
   end

   def add_group(title)
   
      if @first_group == nil
         @first_group = title
         @group_to_id[title] = 0
         return nil
      end
   
      group = {}
      
      # Dynamic
      group['id'] = @group_id += 1
      #group['position'] = @group_id
      group['title'] = title
      
      # Static
      group['color'] = 'FFFFFF'
      group['position'] = 99
   
      @group_hash[@group_id - 1] = group
      @group_to_id[title] = @group_id
   
      return group
   
   end
   
   def add_dial(group, title, url)
   
      if !@group_to_id.key?(group)
         add_group(group)
      end
   
      dial = {}
      
      # Dynamic
      dial['id'] = @dial_id += 1
      dial['title'] = title
      dial['url'] = url
      dial['thumbnail'] = get_thumbnail(title, url)
      dial['idgroup'] = @group_to_id[group]
      dial['ts_created'] = Time.now.to_i
      
      # Static
      dial['visits'] = 0
      dial['visits_morning'] = 0
      dial['visits_afternoon'] = 0
      dial['visits_evening'] = 0
      dial['visits_night'] = 0
      dial['position'] = 999
      
      @dial_hash[@dial_id - 1] = dial
      
      return dial
      
   end
   
   def get_random_ip
   
      valid = false
      while !valid
      
         begin
            ip = IPAddr.new(rand(2**32),Socket::AF_INET).to_s
            host = Resolv.new.getname(ip) 
            puts "#{c} #{real_ip.length} #{ip} #{host}" 
         rescue Exception => e
         end
      
         valid = true
      
      end
      
      return ip
   
   end
   
   def get_thumbnail(title, url)
      
      puts title + " : " + url
      
      ip = get_random_ip
      uri = URI.parse(url)
      base = uri.host
      
      # Need to remove any TLD
      base = base.gsub('.com', '')
      base = base.gsub('.net', '')
      base = base.gsub('.org', '')
      base = base.gsub('.gov', '')
      
      base = base.gsub('.or.jp', '')
      base = base.gsub('.jp', '')
      base = base.gsub('.co.uk', '')
      base = base.gsub('.se', '')
      base = base.gsub('.de', '')
      base = base.gsub('.be', '')
      base = base.gsub('.in', '')
      
      # Split on period.
      # If first result is www, use second.
      base = base.split('.')[-1]

      # Begin the api query
      query = 'https://ajax.googleapis.com/ajax/services/search/images?v=1.0'
      
      # Add a random valid IP address
      query += '&userip=' + ip
      
      # Add the base and logo keyword
      query += '&q=' + base + '%20logo'
      
      # Safe
      query += '&safe=active'

      # Medium size
      # query += '&imgsz=medium'
      
      # Full color
      # query += '&imgc=color'
      
      # Wide aspect ratio
      # Unknown
      
      f = open(query)
      j = JSON.parse(f.read)
      begin
         if j['responseData']['results'].length > 0
            return j['responseData']['results'][0]['url']
         else
            return ''
         end
      rescue Exception => e
         return ''
      end
   end

   def dump
   
      output = {}
      output['groups'] = groups
      output['dials'] = dials
      output['settings'] = settings
      return JSON.pretty_generate(output)
   
   end

   def settings
   
      output = {}
      
      # Dynamic
      output['options.defaultGroupName'] = @first_group
      
      # Static
      output['firstTime'] = 'false'
      output['options.alwaysNewTab'] = '0'
      output['options.apps.align'] = 'center'
      output['options.apps.iconsize'] = 'medium'
      output['options.apps.position'] = 'bottom'     
      output['options.apps.show'] = '0'
      output['options.apps.theme'] = 'dark'
      output['options.background'] = 'http://farm6.static.flickr.com/5134/5565626330_a8ef933e18_o.jpg'
      output['options.backgroundPattern'] = 'http://farm6.static.flickr.com/5137/5565048757_357eda6018_o.jpg'
      output['options.backgroundPosition'] = 'center top'
      output['options.centerThumbnailsVertically'] = '1'
      output['options.centerVertically'] = '1'
      output['options.colors.bg'] = 'undefined'
      output['options.colors.border'] = 'CCCCCC'
      output['options.colors.borderover'] = '999999'
      output['options.colors.dialbg'] = 'FFFFFF'
      output['options.colors.dialbginner'] = 'FFFFFF'
      output['options.colors.dialbginnerover'] = 'FFFFFF'
      output['options.colors.dialbgover'] = 'FFFFFF'
      output['options.colors.title'] = '8C7E7E'
      output['options.colors.titleover'] = '333333'
      output['options.columns'] = '4'
      output['options.dialSpace'] = '90'
      output['options.dialspacing'] = '24'
      output['options.dialstyle.corners'] = '4'
      output['options.dialstyle.shadow'] = 'glow'
      output['options.dialstyle.titleposition'] = 'bottom'
      output['options.fontface'] = 'Helvetica,\"Helvetica Nueue\";arial,sans-serif'
      output['options.fontsize'] = '11'
      output['options.fontstyle'] = 'font-weight:normal;font-style:normal;'
      output['options.highlight'] = '0'
      output['options.order'] = 'position'
      output['options.padding'] = '4'
      output['options.refreshThumbnails'] = '0'
      output['options.repeatbackground'] = 'no-repeat'
      output['options.scrollLayout'] = '1'
      output['options.showAddButton'] = '1'
      output['options.showContextMenu'] = '0'
      output['options.showOptionsButton'] = '0'
      output['options.showTitle'] = '1'
      output['options.showVisits'] = '0'
      output['options.sidebar'] = '0'
      output['options.sidebaractivation'] = 'position' 
      output['options.sidebar.showApps'] = '0'
      output['options.sidebar.showBookmarks'] = '1'
      output['options.sidebar.showBookmarksURL'] = '0'
      output['options.sidebar.showDelicious'] = '0'
      output['options.sidebar.showHistory'] = '0'
      output['options.thumbnailQuality'] = 'medium'
      output['options.titleAlign'] = 'center'
      output['options.useDeliciousShortcut'] = '0'
      output['refresh_create'] = 'false'
      output['refresh_id'] = ''
      output['refreshThumbnail'] = ''
      output['refresh_url'] = ''
      output['requestThumbnail'] = ''
      output['sys.cellspacing'] = '24'
      output['sys.cols'] = '4'
      output['sys.containerwidth'] = '1512px'
      output['sys.dialheight'] = '225.6'
      output['sys.dialwidth'] = '360'
      output['sys.rows'] = '2'
      output['sys.rowspacing'] = '24'
      output['v1590'] = 'false'
      
      return output
      
   end

end

opts = Trollop::options do
   
   opt :input, "Input yaml file", :type => :string
   opt :output, "Output json file", :type => :string
   
end

Trollop::die :input, "Must specify input yaml file" unless opts[:input]
Trollop::die :output, "Must specify output json file" unless opts[:output]
Trollop::die :input, "Must specify input yaml file" unless File.exist?(opts[:input])

s = SpeedDial.new
y = YAML.load_file(opts[:input])
s.parse(y)
j = s.dump
File.open(opts[:output], 'w'){|f| f.write(j)}

