# frozen_string_literal: true

module Paginates
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 10

  private

  def paginate(scope, page_param: :page, per_page: DEFAULT_PER_PAGE)
    requested = params[page_param].to_i
    page = requested.positive? ? requested : 1
    per_page = per_page.to_i
    per_page = DEFAULT_PER_PAGE if per_page < 1

    total = paginate_total(scope)
    total_pages = [ (total.to_f / per_page).ceil, 1 ].max
    page = page.clamp(1, total_pages)

    records = scope.offset((page - 1) * per_page).limit(per_page)

    PageSlice.new(records:, page:, per_page:, total:, param: page_param)
  end

  def paginate_total(scope)
    if scope.is_a?(ActiveRecord::Relation)
      scope.except(:select, :order, :includes, :eager_load, :preload, :group, :limit, :offset).count
    else
      Array(scope).size
    end
  end
end
