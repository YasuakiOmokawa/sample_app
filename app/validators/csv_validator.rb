class CsvValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value.size >= 3
      record.errors[attribute] << (options[:message] || "データ数は3行以上にしてください")
    end
  end
end
