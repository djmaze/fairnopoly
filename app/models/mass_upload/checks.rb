# encoding: UTF-8
#
# == License:
# Fairnopoly - Fairnopoly is an open-source online marketplace.
# Copyright (C) 2013 Fairnopoly eG
#
# This file is part of Fairnopoly.
#
# Fairnopoly is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairnopoly is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairnopoly.  If not, see <http://www.gnu.org/licenses/>.
#
module MassUpload::Checks
  extend ActiveSupport::Concern

  MAX_ARTICLES = 10000
  ALLOWED_MIME_TYPES = ['text/csv']
  AlLOWED_WINDOWS_MIME_TYPES = ['application/vnd.ms-excel', 'application/octet-stream']

  def file_selected?
    if file
      return true
    else
      errors.add(:file, I18n.t('mass_uploads.errors.missing_file'))
      return false
    end
  end

  def csv_format?
    if ALLOWED_MIME_TYPES.include?(file.content_type) or
      (AlLOWED_WINDOWS_MIME_TYPES.include?(file.content_type) and
      file.original_filename[-4..-1] == '.csv')
      return true
    else
      errors.add(:file, I18n.t('mass_uploads.errors.wrong_mime_type'))
      return false
    end
  end

  def open_csv
    @csv = []
    begin
      CSV.foreach(file.path, encoding: get_csv_encoding(file.path), col_sep: ';', quote_char: '"', headers: true) do |row|
        row.delete '€'
        @csv << row
      end
    rescue ArgumentError
      errors.add(:file, I18n.t('mass_uploads.errors.wrong_encoding'))
      return false
    rescue CSV::MalformedCSVError
      errors.add(:file, I18n.t('mass_uploads.errors.illegal_quoting'))
      return false
    end
    return true
  end

  def correct_article_count?
    if @csv.size <= MAX_ARTICLES
      return true
    else
      errors.add(:file, I18n.t('mass_uploads.errors.wrong_file_size'))
      return false
    end
  end

  #def correct_header?
  #  # Ensure all fields defined in header_row are present. Order and additional fields don't matter.
  #  if (MassUpload.header_row - @csv[0].headers).empty?
  #    return true
  #  else
  #    errors.add(:file, I18n.t('mass_uploads.errors.wrong_header'))
  #    return false
  #  end
  #end

  private

    def get_csv_encoding path_to_csv
      match_euro_sign = File.new(path_to_csv, "r").getc
      case match_euro_sign
      when "\xDB"
        'MacRoman'
      when "\x80"
        'Windows-1252'
      when "\?"
        'IBM437'
      when "\xA4"
        'ISO-8859-15'
      else
        'utf-8'
      end
    end

end
