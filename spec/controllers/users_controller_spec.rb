require 'spec_helper'

require 'holiday_japan'
require 'parallel'
require 'securerandom'
require "retryable"
require 'user_func'
require 'create_table'
require 'insert_table'
require 'update_table'
include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils

describe UsersController do

  describe "GET 'create_home" do
    it "配列データが一意でなければtrueを返すこと" do
      d = %w(1.0 2.0 2.0)
      expect(is_not_uniq?(d)).to eq(true)
    end

    it "配列データが一意であればtrueを返さないこと" do
      d = %w(1.0 1.0 1.0)
      expect(is_not_uniq?(d)).not_to eq(true)
    end
  end

end
