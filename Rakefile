
task :all => [:templates]

task :templates => ["templates/classes.eruby"]

rule ".eruby" => [".html", ".plogic"] do |t|
  sh "kwartz -l erubis -p #{t.sources[1]} #{t.sources[0]} > #{t.name}"
end

task :clear do |t|
  rm_f Dir.glob("templates/*.eruby")
end
