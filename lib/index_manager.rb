require 'aws-sdk-s3'
class IndexManager

  def initialize
  end

  def unindex_deleted_releases!

  end

  def index_unindexed_releases!

  end

  def unindexed_releases

  end

  def deleted_releases_still_indexed

  end

  def has_unindexed_releases?

  end

  def has_indexed_deleted_releases?

  end

  def needs_index_update?
    has_unindexed_releases? || has_indexed_deleted_releases?
  end

  def current_releases
    @current_releases ||= RexReleases.new
  end

  def current_release_ids
    @current_relese_ids ||= current_releases.map(&:id)
  end

  def indexed_release_ids

  end

end
