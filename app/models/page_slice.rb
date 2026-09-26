# frozen_string_literal: true

# Simple offset/limit pagination for admin tables. No gem.
class PageSlice
  attr_reader :records, :page, :per_page, :total, :param

  def initialize(records:, page:, per_page:, total:, param: :page)
    @records = records
    @page = page
    @per_page = per_page
    @total = total
    @param = param
  end

  def total_pages
    [ (total.to_f / per_page).ceil, 1 ].max
  end

  def offset
    (page - 1) * per_page
  end

  def from
    return 0 if total.zero?

    offset + 1
  end

  def to
    [ offset + records.size, total ].min
  end

  def multiple_pages?
    total_pages > 1
  end

  def prev_page
    page - 1 if page > 1
  end

  def next_page
    page + 1 if page < total_pages
  end

  def empty?
    total.zero?
  end
end
