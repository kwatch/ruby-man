
task :default => [:all]

task :all => [:templates, :r187, :r191]

task :templates => ["templates/index.eruby", "templates/class.eruby"]

rule ".eruby" => [".html", ".plogic"] do |t|
  sh "kwartz -l erubis -p #{t.sources[1]} #{t.sources[0]} > #{t.name}"
end


def _refman(ver)
  outdir = "public/#{ver}"
  mkdir_p outdir
  sh "ruby -Ke refman.rb -r #{ver}"
end

task :r187 => ["refman.rb", "templates/index.eruby"] do |t|
  _refman('1.8.7')
end

task :r191 => ["refman.rb", "templates/index.eruby"] do |t|
  _refman('1.9.1')
end

task :clear do |t|
  rm_rf ["public/1.8.7", "public/1.9.1"]
  rm_f Dir.glob("templates/*.eruby")
end
