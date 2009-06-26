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
class_entries = {}
File.open(File.join($classes_dir, "=index")) do |f|
  f.each_line do |line|
    entry_name, class_name = line.strip.split(/\t/, 2)
    class_entries[class_name] = entry_name
  end
end

class_paths = {}
module_paths = {}
exception_paths = {}
builtin_classes.each do |class_name, klass|
  entry_name = class_entries[klass.name]
  if entry_name.nil?
    $stderr.puts "*** error: entry name is not found for #{klass.name} class"
  else
    #path = "#{$classes_dir}/#{encode_name(entry_name)}"
    filename = entry_name.gsub(/[A-Z]/) { "-#{$&.downcase}" }.gsub(/::/, '=')
    filepath = "#{$classes_dir}/#{filename}"
    File.file?(filepath)  or raise "#{filepath}: not found (for #{entry_name})."
    #puts "#{klass.name}\t#{filepath}"
    dict = klass <= Exception   ? exception_paths : \
           klass.class == Class ? class_paths     : module_paths
    dict[klass] = filepath
  end
end

require 'erubis'
template_filename = "templates/classes.eruby"
eruby = Erubis::Eruby.new(File.read(template_filename))
context = {
  :class_paths     => class_paths,
  :module_paths    => module_paths,
  :exception_paths => exception_paths,
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

