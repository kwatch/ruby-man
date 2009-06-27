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

def str_jleft(str, len)
  ## required $KCODE
  return "" if len <= 0
  s = str[0, len]
  s[-1, 1] = '' unless s =~ /.\z/
  return s
end

$KCODE = 'euc-jp'

def url_escape(str)
  return str.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
    '%' + $1.unpack('H2' * $1.size).join('%').upcase
  }.tr(' ', '+')
end
  



class Entry

  def initialize
    @rank = 1
  end

  attr_accessor :type, :library, :superclass, :extended, :included
  attr_accessor :content, :name, :filepath, :url, :desc, :klass, :rank

  def [](name)
    return self.instance_variable_get("@#{name}")
  end

  def []=(name, value)
    self.instance_variable_set("@#{name}", value)
  end

  def load_file(filepath)
    str = File.read(filepath)
    header, content = str.split(/\n\n/, 2)
    entry = self
    header.each_line do |line|
      key, val = line.strip.split(/=/, 2)
      self[key] = val
    end
    self.content = content
    return self
  end

  def important?
    return @rank >= 3
  end

  def short_desc(len=80)
    unless @short_desc
      desc = self.desc.to_s.gsub(/\[\[\w:(.*?)\]\]/, '\1')
      @short_desc = desc.length <= len ? desc : str_jleft(desc, len-3) + '...'
    end
    return @short_desc
  end

  def _trim_desc(desc)
    return desc.gsub(/\n/, '').gsub(/\[\[[a-z]:(.*?)\]\]/, '\1')
  end
 
end


class ClassEntry < Entry

  attr_accessor :extended, :included
  attr_accessor :children, :ancestors

  def url
    return @url ||= (@name.nil? ? nil : @name.gsub(/::/, '--') + '.html')
  end

  def desc
    #return @content.to_s.split(/\n\n/, 2).first.gsub(/\n/, '')
    #@content.to_s =~ /\n\n/
    content = @content.to_s
    pos = content.index(/\n\n/)
    return _trim_desc(pos ? content[0..pos] : content)
  end

end


class MethodEntry < Entry

  attr_accessor :parent

  def url
    name = @name[0] == ?# ? @name[1..-1] : @name
    return "##{url_escape(name)}"
  end

  def desc
    #return @content.to_s.split(/\n\n/, 3)[1].gsub(/\n/, '')
    @content.to_s =~ /\n\n(.*?)\n\n/m
    return _trim_desc($1.to_s)
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

  def load_class_entries
    ## get entries
    entries = {}
    File.open(File.join($classes_dir, "=index")) do |f|
      f.each_line do |line|
        ## datafile path
        entry_name, class_name = line.strip.split(/\t/, 2)
        filename = entry_name.gsub(/[A-Z]/) { "-#{$&.downcase}" }.gsub(/::/, '=')
        filepath = "#{$classes_dir}/#{filename}"
        unless File.exist?(filepath)
          #report_error "#{filepath}: not found (#{class_name})"
          next
        end
        ## load datafile
        entry = ClassEntry.new.load_file(filepath)
        entry.name = class_name
        entry.filepath = filepath
        ## select only built-in class
        if entry.library == '_builtin'
          entry.rank = 3 if important?(class_name)
          entries[class_name] = entry
        end
      end
    end
    return entries
  end

  def load_method_entries(class_entry)
    s = class_entry.name.gsub(/[A-Z]/) { "-#{$&.downcase}" }
    dir = "#{$methods_dir}/#{s.gsub(/::/, '=')}"
    method_names = []
    File.open("#{dir}/=index") do |f|
      f.each_line do |line|
        method_name, method_name_with_class = line.chomp.split(/\t/)
        class_name = method_name_with_class.split(/[.\#]/, 2).first
        if class_name == class_entry.name
          method_names << method_name
        end
      end
    end
    entries = []
    method_names.each do |method_name|
      s = method_name.gsub(/[A-Z]/) { "-#{$&.downcase}" }
      s = s.gsub(/^[.\#]/) { $& == '.' ? 's.' : 'i.' }
      s = s.gsub(/[^.\w]/) { '=' + $&[0].to_s(16) }
      filepath = "#{dir}/#{s}._builtin"
      unless File.exist?(filepath)
        #report_error("#{filepath}: not found. (#{method_name})")
        next
      end
      entry = MethodEntry.new.load_file(filepath)
      entry.name = method_name
      entry.parent = class_entry
      #entries[method_name] = entry
      entries << entry
    end
    entries = entries.sort_by {|ent| ent.name }
    #class_entry.children = entries
    return entries
  end

  def build_index(entries)
    ## classify entries
    class_entries = {}
    module_entries = {}
    exception_entries = {}
    object_entries = {}
    entries.each do |class_name, entry|
      next if class_name.start_with?('Errno::') && class_name != 'Errno::EXXX'
      next if class_name == "fatal"
      begin
        klass = get_class(class_name)
        dict = entry.type == 'object' ? object_entries    : \
               klass <= Exception     ? exception_entries : \
               klass.class == Class   ? class_entries     : module_entries
      rescue NameError => ex   # when class_name == "Errno::EXXX"
        klass = nil
        dict = exception_entries
      end
      entry.klass = klass
      dict[class_name] = entry
    end
    ## render html
    context = {
      :class_entries     => class_entries,
      :module_entries    => module_entries,
      :exception_entries => exception_entries,
    }
    html = render("templates/index.eruby", context)
    return html
  end

  def build_class_html(class_entry)
    class_entry.children ||= load_method_entries(class_entry)
    context = {:class_entry => class_entry}
    html = render("templates/class.eruby", context)
    return html
  end

  def build_all(basedir='public')
    entries = load_class_entries()
    html = build_index(entries)
    File.open("#{basedir}/index.html", 'w') {|f| f.write(html) }
    ##
    entries.delete_if {|class_name, class_entry|
      class_entry.klass.nil? || class_entry.type == 'object'
    }
    entries.each do |class_name, class_entry|
      class_entry.children ||= load_method_entries(class_entry)
      ancestor_classes = class_entry.klass.ancestors[1..-1]
      ancestor_classes.delete(Kernel)
      class_entry.ancestors = ancestor_classes.collect {|klass| entries[klass.name] }
    end
    entries.each do |class_name, class_entry|
      html = build_class_html(class_entry)
      filename = "#{basedir}/#{class_entry.url}"
      File.open(filename, 'w') {|f| f.write(html) }
    end
  end

  def render(template_filepath, context)
    require 'erubis'
    eruby = Erubis::Eruby.new(File.read(template_filepath))
    return eruby.evaluate(context)
  end

end


if __FILE__ == $0
  Builder.new.build_all
end

