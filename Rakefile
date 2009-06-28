
task :default => [:all]

task :all => [:templates, :r187]

task :templates => ["templates/index.eruby", "templates/class.eruby"]

rule ".eruby" => [".html", ".plogic"] do |t|
  sh "kwartz -l erubis -p #{t.sources[1]} #{t.sources[0]} > #{t.name}"
end


task :r187 => ["refman.rb", "templates/index.eruby"] do |t|
  outdir = "public/1.8.7"
  mkdir_p outdir
  sh "ruby refman.rb -r 1.8.7"
end

task :clear do |t|
  rm_rf "public/1.8.7"
  rm_f Dir.glob("templates/*.eruby")
end
