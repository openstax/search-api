require 'rails_helper'
require 'vcr_helper'

describe OpenStax::Cnx::V1::Book, type: :external, vcr: VCR_OPTS do
  let(:cnx_book_id) { '405335a3-7cff-4df2-a9ad-29062a4af261' }

  let(:expected_book_url) {
    'https://archive.cnx.org/contents/405335a3-7cff-4df2-a9ad-29062a4af261'
  }

  it "provides info about the book with the given id" do
    book = OpenStax::Cnx::V1::Book.new(id: cnx_book_id)
    expect(book.id).to eq cnx_book_id
    expect(book.hash).not_to be_blank
    expect(book.url).to eq expected_book_url
    expect(book.uuid).to eq cnx_book_id
    expect(book.version).to eq '7.3'
    expect(book.title).to eq 'College Physics with Courseware'
    expect(book.tree).not_to be_nil
    expect(book.root_book_part).to be_a OpenStax::Cnx::V1::BookPart
  end
end
