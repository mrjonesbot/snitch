namespace :snitch do
  namespace :tailwind do
    desc "Build Snitch Tailwind CSS"
    task :build do
      require "tailwindcss/ruby"

      gem_root = File.expand_path("../..", __dir__)
      input = File.join(gem_root, "app/assets/stylesheets/snitch/application.css")
      output = File.join(gem_root, "app/assets/builds/snitch/application.css")

      FileUtils.mkdir_p(File.dirname(output))

      system(Tailwindcss::Ruby.executable,
             "-i", input,
             "-o", output,
             "--minify",
             exception: true)

      puts "Snitch Tailwind CSS compiled successfully"
    end
  end
end
