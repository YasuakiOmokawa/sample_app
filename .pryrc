Pry.config.pager = false

def Pry.set_color sym, color
  CodeRay::Encoders::Terminal::TOKEN_COLORS[sym] = color.to_s
  { sym => color.to_s }
end

Pry.set_color :constant, "\e[1;32;4m"
Pry.set_color :integer, "\e[1;33m"
Pry.set_color :imaginary, "\e[1;33m"
Pry.set_color :annotation, "\e[32m"
Pry.set_color :function, "\e[1;32m"
Pry.set_color :doctype, "\e[1;32m"
Pry.set_color :id, "\e[1;32m"
Pry.set_color :pseudo_class, "\e[1;32m"
Pry.set_color :type, "\e[1;32m"
Pry.set_color :variable, "\e[32m"

if defined?(PryByebug)
  Pry.commands.alias_command 'c', 'continue'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'f', 'finish'
end
