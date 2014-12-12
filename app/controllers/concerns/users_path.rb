module UsersPath

  class AllUserPath
    def initialize(id)
      @id = id
    end

    def path
      ApplicationController.helpers.all_user_path(@id)
    end
  end
end
