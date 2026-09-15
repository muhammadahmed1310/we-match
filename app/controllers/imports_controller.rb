# frozen_string_literal: true

class ImportsController < ApplicationController
  MAX_BYTES = 5.megabytes

  def new
  end

  def create
    @create_missing_groups = ActiveModel::Type::Boolean.new.cast(params[:create_missing_groups]).present?

    import = build_import
    return if performed?

    if confirmed?
      @result = import.commit!

      if @result.ok?
        redirect_to members_path, notice: import_notice(@result)
      else
        @import_payload = @result.payload_json
        flash.now[:alert] = @result.header_error || "Nothing was imported — some rows still have problems."
        render :preview, status: :unprocessable_entity
      end
    else
      @result = import.preview
      @import_payload = @result.payload_json
      render :preview
    end
  end

  private

  def confirmed?
    params[:confirm].present?
  end

  def build_import
    if params[:import_payload].present?
      return PeopleImport.from_payload(params[:import_payload], create_missing_groups: @create_missing_groups)
    end

    uploaded = params[:file]
    if uploaded.blank?
      flash.now[:alert] = "Choose an Excel (.xlsx) file to import."
      render :new, status: :unprocessable_entity
      return
    end

    if uploaded.size.to_i > MAX_BYTES
      flash.now[:alert] = "That file is larger than 5 MB. Split it into smaller batches."
      render :new, status: :unprocessable_entity
      return
    end

    filename = uploaded.original_filename.to_s
    unless File.extname(filename).downcase == ".xlsx"
      flash.now[:alert] = "Please upload an Excel file ending in .xlsx (not CSV)."
      render :new, status: :unprocessable_entity
      return
    end

    begin
      rows = PeopleImport.read_xlsx(uploaded)
      PeopleImport.new(rows, create_missing_groups: @create_missing_groups)
    rescue ArgumentError => e
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
      nil
    end
  end

  def import_notice(result)
    "Imported #{result.created} new person(s), updated #{result.updated}, left #{result.unchanged} unchanged."
  end
end
