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



def get_class(name)
  obj = Object
  name.split(/::/).each {|s| obj = obj.const_get(s) }
  return obj
end

def report_error(msg)
  #$stderr.puts "*** #{msg}"
  warn "*** #{msg}"
end


class Entry
  
  def initialize
    @rank = 1
  end

  attr_accessor :type, :library, :superclass, :extended, :included
  attr_accessor :content, :name, :filepath, :url, :desc, :klass, :rank

  def load_file(filepath)
    str = File.read(filepath)
    header, content = str.split(/\n\n/, 2)
    entry = self
    header.each_line do |line|
      key, val = line.strip.split(/=/, 2)
      self.__send__("#{key}=", val)
    end
    self.content = content
    return self
  end

  def desc
    return @desc ||= @content.to_s.split(/\n\n/, 2).first.gsub(/\n/, '')
  end

  def url
    return @url ||= @name.gsub(/::/, '--') + '.html'
  end

  def important?
    return @rank >= 3
  end

end


class Builder

  IMPORTANT_CLASSES = dict = {}
  %w[
    Object String Array Hash File Dir Struct Class Module Proc Range Regexp Symbol Time
    Enumerable Kernel Math
    Exception StandardError RuntimeError
  ].each {|x| dict[x] = true }

  def important?(name)
    return IMPORTANT_CLASSES.key?(name)
  end

  def build_index
    ## get entries
    entries = []
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
        entry = Entry.new.load_file(filepath)
        entry.name = class_name
        entry.filepath = filepath
        ## select only built-in class
        if entry.library == '_builtin'
          entry.rank = 3 if important?(class_name)
          entries << entry
        end
      end
    end
    ## classify entries
    class_entries = {}
    module_entries = {}
    exception_entries = {}
    object_entries = {}
    entries.each do |entry|
      next if entry.name.start_with?('Errno::') && entry.name != 'Errno::EXXX'
      next if entry.name == "fatal"
      begin
        klass = get_class(entry.name)
        dict = entry.type == 'object' ? object_entries    : \
               klass <= Exception     ? exception_entries : \
               klass.class == Class   ? class_entries     : module_entries
      rescue NameError => ex   # when class_name == "Errno::EXXX"
        klass = nil
        dict = exception_entries
      end
      entry.klass = klass
      dict[entry.name] = entry
    end
    ## render html
    context = {
      :class_entries     => class_entries,
      :module_entries    => module_entries,
      :exception_entries => exception_entries,
    }
    html = render("templates/classes.eruby", context)
    return html
  end

  def render(template_filepath, context)
    require 'erubis'
    eruby = Erubis::Eruby.new(File.read(template_filepath))
    return eruby.evaluate(context)
  end

end


if __FILE__ == $0
  print Builder.new.build_index
end

