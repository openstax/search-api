module Books::IndexingStrategies::I1
  # The indexing strategy is the encapsulation for the index's structure and
  # inspect (including index settings & mappings).
  #
  # The strategy also declares what page element objects it wants indexed.
  class Strategy
    prefix_logger "Books::IndexingStrategies::I1::Strategy"

    SHORT_NAME = "i1"
    NUM_SHARDS = 1
    NUM_REPLICAS = 1

    delegate :short_name, to: :class

    def self.short_name
      SHORT_NAME
    end

    def index_metadata
      @index_meta ||= begin
        metadata_hashes = [settings, mappings]
        metadata_hashes.inject({}) { |aggregate, hash| aggregate.merge! hash }
      end
    end

    def index(book:, index_name:)
      documents = BookDocs.new(book: book).docs

      log_info("Creating index #{index_name} with #{documents.count} documents")
      documents.each {|document| index_document(document: document, index_name: index_name) }
      log_info("Finished creating index #{index_name}")
    end

    def total_number_of_documents_to_index(book:)
      BookDocs.new(book: book).docs.count
    end

    private

    def index_document(document:, index_name:)
      begin
        OsElasticsearchClient.instance.index(index: index_name,
                                             type:  document.type,
                                             body:  document.body)
      rescue ElementIdMissing => ex
        Raven.capture_message(ex.message, :extra => element.to_json)
        log_error(ex)
      end
    end

    def settings
      {
        settings: {
          index: {
            number_of_shards: NUM_SHARDS,
            number_of_replicas: NUM_REPLICAS
          },
          analysis: {
            analyzer: {
              default: {
                tokenizer: "standard",
                char_filter: [
                  "quotes"
                ],
                filter: [
                  "lowercase"
                ]
              }
            },
            char_filter: {
              quotes: {
                mappings: [
                  "’=>'",
                ],
                type: "mapping"
              }
            }
          }
        }
      }
    end

    def mappings
      { mappings: {} }.merge(PageElementDocument.mapping)
    end
  end
end
