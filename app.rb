require 'sinatra'
require 'commonmarker'
require 'front_matter_parser'
require 'json'
require 'zip'
require 'mimemagic'
require 'mimemagic/overlay'

### Load posts ###

front_matter_parser = FrontMatterParser::Parser.new(
  :md,
  loader: FrontMatterParser::Loader::Yaml.new(whitelist_classes: [Time])
)

posts_zip = Dir.glob('zip_files/*_posts.zip').first
match = posts_zip.match(/zip_files\/esa_.+_(md|json)_v2_.+_posts.zip/)
export_format =
  case match[1]
  when "md"; :markdown
  when "json"; :json
  else raise "invalid export format: #{match[1]}"
  end

puts "[info] export v2 (#{export_format})"

posts = {}
Zip::File.open(posts_zip) do |zip_file|
  zip_file.each do |entry|
    next unless entry.file?

    path = '/' + entry.name
    content = entry.get_input_stream.read.force_encoding('UTF-8')
    if export_format == :markdown
      parsed = front_matter_parser.call(content)
      posts[parsed['number']] = parsed.front_matter.merge('path' =>  path, 'content' => parsed.content)
    elsif export_format == :json
      parsed = JSON.parse(content)
      post = parsed["post"]
      posts[post['number']] = {
        'title' => post['name'],
        'published' => !post['wip'],
        'path' =>  path,
        'content' => post['body_md']
      }.merge(post.slice('created_at', 'updated_at', 'number'))
    end
  rescue
    puts "[warning] parse failure: #{path}"
  end
end
posts = posts.sort.to_h

### Index attachment files ###

files = {}
files_zips = Dir.glob('zip_files/*_files_*.zip').sort.select { |path| path.match?(/files_\d+\.zip$/) }.each(&:freeze)
files_zips.each do |files_zip|
  Zip::File.open(files_zip) do |zip_file|
    zip_file.each do |entry|
      next unless entry.file?

      # entry.name: "files_0/2020/12/25/1/foo.png"
      # files["2020/12/25/1/foo.png"] = "zip_files/esa_foo_md_v2_2020-12-26_09-39-46_files_0.zip"
      files[entry.name.split('/', 2).last] = files_zip
    end
  end
end

### Routes ###

get '/' do
  @posts = posts
  erb :index
end

get '/posts/:id' do
  @post = posts[params[:id].to_i]
  return "Not Found" unless @post

  doc = CommonMarker.render_doc(
    @post['content'],
    %i[DEFAULT FOOTNOTES STRIKETHROUGH_DOUBLE_TILDE VALIDATE_UTF8],
    %i[table strikethrough autolink]
  )
  @content_html = doc.to_html(%i[DEFAULT HARDBREAKS UNSAFE SOURCEPOS TABLE_PREFER_STYLE_ATTRIBUTES])

  erb :post
end

get '/files/*' do
  files_zip = files[params[:splat].first]
  raise Sinatra::NotFound unless files_zip

  zip_number = files_zip.scan(/files_(\d+)\.zip$/).flatten.first
  Zip::File.open(files_zip) do |zip_file|
    entry = zip_file.glob("files_#{zip_number}/#{params[:splat].first}").first
    entry.get_input_stream.read.tap do |content|
      content_type MimeMagic.by_magic(content)
    end
  end
end
