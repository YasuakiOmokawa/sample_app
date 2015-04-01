require('csv')

module UserUploaded

  class UploadedFile

    def initialize(file_path)
      @arr_of_arrs = CSV.read(file_path)
    end

  end
end
