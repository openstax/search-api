class LoadTestingUrlsWriter
  LOAD_URLS_FILE_NAME = "load_urls.txt"

  def initialize(env:, num_different_books: 3, urls_per_book: 3)
    @num_different_books = num_different_books
    @urls_per_book = urls_per_book
    @env = env
  end

  def call
    book_ids_to_use = sample_some_books_ids
    File.open(LOAD_URLS_FILE_NAME, 'w') do |file|
      book_ids_to_use.each do |book_id|
        terms_to_use = find_terms_in_book_to_search_for(book_id)
        write_urls(file, book_id, terms_to_use)
      end
    end
  end

  private

  def write_urls(file, book_id, terms_to_use)
    terms_to_use.each do |term|
      stripped = term.gsub(/[^a-z0-9\-\s]/i, '').strip
      url = "https://search-#{@env}.sandbox.openstax.org/open-search/api/v0/search?q=#{stripped}&books=#{book_id}&index_strategy=i1&search_strategy=s1"
      file.puts url
    end
  end

  def find_terms_in_book_to_search_for(book_id)
    book = OpenStax::Cnx::V1::Book.new(id: book_id)
    random_docs = Books::IndexingStrategies::I1::BookDocs.new(book: book).docs.sample(@urls_per_book)
    random_docs.each_with_object([]) do |doc, accum|
      accum << doc.visible_content.split(' ').sort_by(&:length).reverse.first
    end
  end

  def sample_some_books_ids
    book_states = BookIndexState.live
    book_ids = book_states.map(&:book_version_id)
    book_ids.sample(@num_different_books)
  end
end
