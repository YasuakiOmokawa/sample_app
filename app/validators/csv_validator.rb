class CsvValidator < ActiveModel::EachValidator
  require 'user_func'
  include ParamUtils

  def validate_each(record, attribute, value)
    unless value.size >= 4
      record.errors[attribute] << (options[:message] || "データ数は3行以上にしてください")
    end
    if value.size >= 4
      unless value.first[0] == "date" && value.first[1] == "value"
        record.errors[attribute] << (options[:message] || "ヘッダ書式が間違っています")
      end
      unless value.map{|t| t[0]}.compact.size == value.map{|t| t[1]}.compact.size
        record.errors[attribute] << (options[:message] || "日付と値の数は同じにしてください")
      end
      begin
        a = value.map{|t| t[0]}
        a.delete("date")
        b = a.map{|t| set_date_format(t) }
        from = set_date_format(a.first)
        to = set_date_format(a.last)
        unless (from..to).map { |t| t }.size == b.size
          record.errors[attribute] << (options[:message] || "日付は連続データを入力し、開始日付は終了日付の前日にしてください")
        end
      rescue
        record.errors[attribute] << (options[:message] || "日付はYYYY/MM/DD形式にし、正しい日付を入力してください")
      end
    end
  end
end
