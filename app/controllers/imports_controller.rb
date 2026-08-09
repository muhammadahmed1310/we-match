# frozen_string_literal: true

class ImportsController < ApplicationController
  MAX_BYTES = 1.megabyte

  def new
    @csv_text = ""
  end

  def create
    @csv_text = submitted_csv
    @create_missing_groups = ActiveModel::Type::Boolean.new.cast(params[:create_missing_groups]).present?

    if @csv_text.blank?
      flash.now[:alert] = "Choose a CSV file or paste its contents."
      return render :new, status: :unprocessable_entity
    end

    if @csv_text.bytesize > MAX_BYTES
      flash.now[:alert] = "That file is larger than 1 MB. Split it into smaller batches."
      return render :new, status: :unprocessable_entity
    end

    import = PeopleImport.new(@csv_text, create_missing_groups: @create_missing_groups)

    if confirmed?
      @result = import.commit!

      if @result.ok?
        redirect_to members_path, notice: import_notice(@result)
      else
        flash.now[:alert] = @result.header_error || "Nothing was imported — some rows still have problems."
        render :preview, status: :unprocessable_entity
      end
    else
      @result = import.preview
      render :preview
    end
  end

  private

  def confirmed?
    params[:confirm].present?
  end

  def submitted_csv
    uploaded = params[:file]
    return uploaded.read.force_encoding("UTF-8") if uploaded.respond_to?(:read)

    params[:csv_text].to_s
  end

  def import_notice(result)
    "Imported #{result.created} new person(s), updated #{result.updated}, left #{result.unchanged} unchanged."
  end
end
