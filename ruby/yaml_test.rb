require 'yaml'
require 'erb'

lang = 'frank'
template = ERB.new(File.read("./test.yaml")).result(binding);
puts template.inspect
ruby_obj = YAML::load(template);
#puts YAML::dump(ruby_obj)
puts ruby_obj.inspect
puts ruby_obj['css-common-locale']
