#!/usr/bin/env ruby
# 簡易ERB→Slim変換スクリプト
# 注意: 完全な変換ではなく、基本的な構造のみを変換します

class ErbToSlimConverter
  def self.convert_file(erb_path)
    erb_content = File.read(erb_path)
    slim_content = convert_content(erb_content)
    slim_path = erb_path.sub(/\.erb$/, '.slim')

    File.write(slim_path, slim_content)
    puts "✓ Converted: #{erb_path}"
    slim_path
  end

  def self.convert_content(erb)
    lines = erb.split("\n")
    slim_lines = []
    indent_level = 0
    in_ruby_block = false

    lines.each do |line|
      # 空行
      if line.strip.empty?
        slim_lines << ""
        next
      end

      # コメント
      if line.strip.start_with?('<%#')
        slim_lines << line.gsub(/<%#\s*/, '/! ').gsub(/%>/, '')
        next
      end

      # ERBタグを処理
      converted = line.dup

      # <%= %>を= に変換
      converted.gsub!(/<%=\s*(.+?)\s*%>/) { "= #{$1}" }

      # <% %>を- に変換（制御構造）
      converted.gsub!(/<%-?\s*(.+?)\s*-?%>/) { "- #{$1}" }

      # HTMLタグの処理
      if converted.strip.match?(/^<(\w+)/)
        # 開始タグを検出
        tag_match = converted.match(/^\s*<(\w+)(.*?)>/)
        if tag_match
          tag_name = tag_match[1]
          attrs = tag_match[2]

          # 属性を処理
          slim_attrs = process_attributes(attrs)
          indent = ' ' * (converted.index('<') || 0)

          # 閉じタグがある場合
          if converted.include?("</#{tag_name}>")
            content = converted[converted.index('>')+1...converted.rindex("<")]
            slim_lines << "#{indent}#{tag_name}#{slim_attrs} #{content.strip}" if content && !content.strip.empty?
            slim_lines << "#{indent}#{tag_name}#{slim_attrs}" if content.nil? || content.strip.empty?
          else
            slim_lines << "#{indent}#{tag_name}#{slim_attrs}"
          end
          next
        end
      end

      # 閉じタグだけの行はスキップ
      next if converted.strip.match?(/^<\/\w+>/)

      slim_lines << converted unless converted.strip.empty?
    end

    slim_lines.join("\n")
  end

  def self.process_attributes(attrs_string)
    return "" if attrs_string.nil? || attrs_string.strip.empty?

    # 簡易的な属性処理
    attrs = attrs_string.strip
    return "" if attrs.empty?

    # ERBが含まれる属性
    if attrs.include?('<%=')
      attrs.gsub!(/ (\w+)=["']<%=\s*(.+?)\s*%>["']/) { " #{$1}=#{$2}" }
    end

    # 静的な属性
    slim_attrs = attrs.scan(/(\w+)=["']([^"']*)["']/).map do |name, value|
      if value.empty?
        name
      else
        "#{name}=\"#{value}\""
      end
    end.join(' ')

    slim_attrs.empty? ? "" : " #{slim_attrs}"
  end
end

# app/views配下の全.html.erbファイルを取得
erb_files = Dir.glob("app/views/**/*.html.erb")

puts "Warning: This is a basic converter and may not handle complex ERB correctly."
puts "Manual review and fixes will likely be needed."
puts ""
puts "Found #{erb_files.size} ERB files to convert"
puts "Press Enter to continue or Ctrl+C to cancel..."
STDIN.gets

converted = []
failed = []

erb_files.each do |erb_file|
  begin
    slim_file = ErbToSlimConverter.convert_file(erb_file)
    converted << slim_file
  rescue => e
    puts "✗ Failed: #{erb_file} - #{e.message}"
    failed << erb_file
  end
end

puts "\n" + "="*60
puts "Conversion Summary:"
puts "Successfully converted: #{converted.size} files"
puts "Failed: #{failed.size} files"
puts "="*60

if failed.any?
  puts "\nFailed files:"
  failed.each { |f| puts "  - #{f}" }
end

puts "\nNext steps:"
puts "1. Review converted Slim files manually"
puts "2. Delete ERB files after verification: rm app/views/**/*.html.erb"
puts "3. Run tests to ensure everything works"
