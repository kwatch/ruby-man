
task :all => [:templates, :index]

task :templates => ["templates/classes.eruby", "templates/class.eruby"]

rule ".eruby" => [".html", ".plogic"] do |t|
  sh "kwartz -l erubis -p #{t.sources[1]} #{t.sources[0]} > #{t.name}"
end

index_html = "public/index.html"

task :index => [:remove_index, index_html]

task :remove_index do |t|
  rm_f index_html
end

file index_html => ["refman.rb", "templates/classes.eruby"] do |t|
  mkdir_p File.dirname(t.name)
  #sh "ruby refman.rb > #{t.name}"
  #sh "ruby refman.rb > #{t.name} 2> error.log"
  sh "ruby refman.rb"
end

task :clear do |t|
  rm_f Dir.glob("templates/*.eruby")
end
