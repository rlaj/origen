# Modified from: https://github.com/severinh/nanoc-lunr-js-search/blob/master/lib/nanoc/filters/lunr_js_search.rb
require 'json'
require 'nokogiri'

class SearchFilter < Nanoc::Filter
  identifier :search

  def run(content, params={})
    doc = Nokogiri::HTML(content)
    url = assigns[:item_rep].path
    #first_image = doc.xpath('//img/@src').to_a[0]
    document = {
      # See this next time you need to fix this: https://gist.github.com/LeCoupa/8c305ec8c713aad07b14
      title: extract_first(doc, '//article/*/h1 | //article/*/h2 | //article/h1 | //article/h2'),
      subtitle: extract_first(doc, '//article/*/h3 | //article/h3'),
      body: extract_all(doc, '//article//*/text()'),
      #img: (first_image.nil?) ? '' : first_image.value(),
      #alt: extract_values(doc, '//article//img/@alt')
    }

    if File.exist?(search_file)
      documents = JSON.parse(File.read(search_file))
    else
      documents = {}
    end

    documents[url] = document

    File.open(search_file, 'w') do |file|
      file.write(JSON.pretty_generate(documents))
    end

    content
  end

  def search_file
    if item[:search_id]
      File.join(@site.config[:output_dir], "search_#{item[:search_id]}.json")
    else
      File.join(@site.config[:output_dir], 'search.json')
    end
  end

  def extract_first(doc, path)
    extract_text(doc, path).first
  end

  def extract_all(doc, path)
    extract_text(doc, path).join(' ')
  end

  def extract_text(doc, path)
    doc.xpath(path).to_a.map { |t|
      t.content.gsub('\r', ' ').gsub('\n', ' ').squeeze(' ').strip
    }.reject { |t|
      t.empty?
    }
  end

  def extract_values(doc, path)
    tokens = doc.xpath(path).to_a.map { |t|
      t.value().gsub('\r', ' ').gsub('\n', ' ').squeeze(' ').strip
    }
    tokens.join(' ')
  end
end
