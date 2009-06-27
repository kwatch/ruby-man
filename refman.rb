# -*- coding: utf-8 -*-

builtin_classes = {}
ObjectSpace.each_object do |obj|
  builtin_classes[obj.name] = obj if obj.is_a?(Class)
end
#p builtin_classes

$basedir     = "db-1_8_7"   # or "#{Dir.pwd}/db-1_8_7"
$classes_dir = "#{$basedir}/class"
$methods_dir = "#{$basedir}/method"
#$basedir = File.join(Dir.pwd, 'db-1_8_7')
#$classes_dir = File.join($basedir, 'class')
#$methods_dir = File.join($basedir, 'method')

def decode_path(path)
  s = path
  s = s.gsub(/-([a-z])/) { $1.upcase }
  s = s.gsub(/=(\d[a-f0-9])/) { $1.to_i(16).chr }
  #s = s.gsub(/=21/, '!')
  #s = s.gsub(/=3f/, '?')
  #s = s.gsub(/=/, '::')
  return s
end

def encode_name(name)
  s = name
  s = s.gsub(/([A-Z])/) { "-#{$1.downcase}" }
  s = s.gsub(/[^-:\w]/) { $&[0].to_s(16) }
  #s = s.gsub(/::/, "=")
  #s = s.gsub(/\?/, "=3f")
  #s = s.gsub(/\!/, "=21")
  return s
end


## list of classes
#Dir.glob(File.join($classes_dir, "*")).each do |path|
#  entry = File.basename(path)
#  next if entry == '=index'
#  classname = decode_path(entry)
#  puts classname
#end

def load_datafile(filepath)
  str = File.read(filepath)
  header, content = str.split(/\n\n/, 2)
  entry = {}
  header.each_line do |line|
    key, val = line.strip.split(/=/, 2)
    entry[key.intern] = val
  end
  entry[:content] = content
  return entry
end

def get_class(name)
  obj = Object
  name.split(/::/).each {|s| obj = obj.const_get(s) }
  return obj
end

def class_url(class_name)
  class_name.gsub(/::/, '--') + '.html'
end

def report_error(msg)
  #$stderr.puts "*** #{msg}"
  warn "*** #{msg}"
end

class_entries = {}
module_entries = {}
exception_entries = {}
object_entries = {}
File.open(File.join($classes_dir, "=index")) do |f|
  f.each_line do |line|
    ## datafile path
    entry_name, class_name = line.strip.split(/\t/, 2)
    filename = entry_name.gsub(/[A-Z]/) { "-#{$&.downcase}" }.gsub(/::/, '=')
    filepath = "#{$classes_dir}/#{filename}"
    unless File.exist?(filepath)
      report_error "#{filepath}: not found (#{class_name})"
      next
    end
    ## load datafile
    entry = load_datafile(filepath)
    if entry[:library] == '_builtin'
      next if class_name.start_with?('Errno::') && class_name != 'Errno::EXXX'
      next if class_name == "fatal"
      begin
        klass = get_class(class_name)
        dict = entry[:type] == 'object' ? object_entries    : \
               klass <= Exception       ? exception_entries : \
               klass.class == Class     ? class_entries     : module_entries
      rescue NameError => ex   # when class_name == "Errno::EXXX"
        klass = nil
        dict = exception_entries
      end
      entry[:klass] = klass
      entry[:name] = class_name
      entry[:filepath] = filepath
      entry[:url] = class_url(class_name)
      desc = entry[:content].to_s.split(/\n\n/, 2).first.gsub(/\n/, '')
      entry[:desc] = desc
      dict[class_name] = entry
    end
  end
end


require 'erubis'
template_filename = "templates/classes.eruby"
eruby = Erubis::Eruby.new(File.read(template_filename))
context = {
  :class_entries     => class_entries,
  :module_entries    => module_entries,
  :exception_entries => exception_entries,
}
print eruby.evaluate(context)


## method list of String class
#classname = 'String'
#dir = File.join($methods_dir, encode_name(classname))
#p dir
#Dir.glob(File.join(dir, '*')).each do |path|
#  entry = File.basename(path)
#  methodname = decode_path(entry)
#  puts methodname
#end

