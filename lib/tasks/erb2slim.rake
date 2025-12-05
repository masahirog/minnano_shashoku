namespace :view do
  desc "Convert all ERB templates to Slim"
  task :erb2slim => :environment do
    require 'slim'

    # html2slimのインストールを試みる
    begin
      require 'html2slim'
    rescue LoadError
      puts "Installing html2slim gem..."
      system("gem install html2slim")
      Gem.clear_paths
      require 'html2slim'
    end

    # app/views配下の全.html.erbファイルを取得
    erb_files = Dir.glob("app/views/**/*.html.erb")

    puts "Found #{erb_files.size} ERB files to convert"

    converted_count = 0
    failed_files = []

    erb_files.each do |erb_file|
      slim_file = erb_file.sub(/\.erb$/, '.slim')

      begin
        # ERBファイルをSlimに変換
        File.open(slim_file, 'w') do |f|
          erb_content = File.read(erb_file)
          slim_content = HTML2Slim.convert!(erb_content, :erb)
          f.write(slim_content)
        end

        puts "✓ Converted: #{erb_file} -> #{slim_file}"
        converted_count += 1
      rescue => e
        puts "✗ Failed: #{erb_file} - #{e.message}"
        failed_files << erb_file
      end
    end

    puts "\n" + "="*60
    puts "Conversion complete!"
    puts "Successfully converted: #{converted_count} files"
    puts "Failed: #{failed_files.size} files" if failed_files.any?
    puts "="*60

    if failed_files.any?
      puts "\nFailed files:"
      failed_files.each { |f| puts "  - #{f}" }
    end
  end
end
