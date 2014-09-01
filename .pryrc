Pry.config.color = false
Pry.commands.alias_command 'c', 'continue'
Pry.commands.alias_command 's', 'step'
Pry.commands.alias_command 'n', 'next'
Pry.config.pager = false


load 'user_func.rb'
load 'create_table.rb'
load 'insert_table.rb'
load 'update_table.rb'
include UserFunc, CreateTable, InsertTable, UpdateTable, ParamUtils
