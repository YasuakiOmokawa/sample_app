require 'spec_helper'

require 'holiday_japan'
require 'user_func'
require 'create_table'
require 'insert_table'
require 'update_table'
require 'parallel'
require 'securerandom'
require "retryable"
include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils

describe UsersController do

  describe "GET 'create_home" do
    it "分析対象の日付タイプを取得" do
      # ...
    end
  end

end
