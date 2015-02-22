Airbrake.configure do |config|
  config.api_key = '00424406be5fed8916cbf6c3e4c6e890'
  config.host    = 'senk-errbit.herokuapp.com'
  config.port    = 443
  config.secure  = config.port == 443
end
