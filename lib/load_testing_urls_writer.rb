# Use this (testing) code with caution: it uses a lot of memory
# Note for future: refactor to random content from elasticsearch instead
class LoadTestingUrlsWriter
  LOAD_URLS_FILE_NAME = "load_urls.txt"

  def initialize(env:, num_different_urls: 4)
    @num_different_urls = num_different_urls
    @env = env
    @book_docs = {}
  end

  def call
    File.open(LOAD_URLS_FILE_NAME, 'w') do |file|
      @num_different_urls.times do
        book_id = books_ids.sample
        term = find_term_in_book_to_search_for(book_id)
        puts "LoadTestingWriter writing url for #{book_id} #{term}"
        write_url(file, book_id, term)
      end
    end
  end

  private

  def write_url(file, book_id, term)
    stripped = term.gsub(/[^a-z0-9\-\s]/i, '').strip
    url = "https://search-#{@env}.sandbox.openstax.org/api/v0/search?q=#{stripped}&books=#{book_id}&index_strategy=i1&search_strategy=s1"
    file.puts url
  end

  def book_docs(book_id)
    docs = @book_docs[book_id]
    unless docs.present?
      docs = Books::IndexingStrategies::I1::BookDocs.new(book: OpenStax::Cnx::V1::Book.new(id: book_id)).docs
      @book_docs[book_id] = docs
    end

    docs
  end

  def find_term_in_book_to_search_for(book_id)
    docs = book_docs(book_id)
    random_doc = docs.sample
    random_doc.visible_content.split(' ').sort_by(&:length).reverse.first
  end

  def books_ids
    @book_ids ||= begin
      book_states = BookIndexState.created
      book_states.map(&:book_version_id)
    end
  end
end
