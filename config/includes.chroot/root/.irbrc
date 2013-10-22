# Require some gems
require 'rubygems'
require 'interactive_editor'
require 'wirble'
require 'ap'
require 'what_methods'

# Set some IRB configuration settings
IRB.conf[:AUTO_INDENT] = true
IRB.conf[:USE_READLINE] = true

# Set up a custom prompt
IRB.conf[:PROMPT][:CUSTOM] = {
   :PROMPT_I => "# %n:%i >> ",
   :PROMPT_S => "# %l> ",
   :PROMPT_C => "# > ",
   :PROMPT_N => "# %n:%i > ",
   :RETURN => "# => %s\n"
}
IRB.conf[:PROMPT_MODE] = :CUSTOM

# Allow Wirble to do syntax higlighting and coloring
Wirble.init
Wirble.colorize

# Default to awesome print
# See ~/.aprc for default settings
AwesomePrint.irb!

# Return only the methods not present on basic objects
class Object
   def interesting_methods
      (self.methods - Object.instance_methods).sort
   end
end

