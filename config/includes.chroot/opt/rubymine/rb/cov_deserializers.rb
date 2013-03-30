# require all deserializers
Dir[File.dirname(__FILE__) + '/deserializers/*.rb'].each do |file|
  require file
end