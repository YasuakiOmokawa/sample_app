module ContentsHelper

  def get_users_contents(id)
    contents = Content.where(user_id: id).reduce({}) do |acum, item|
      acum[item.upload_file_name] = item.id
      acum
    end
  contents
  end
end
