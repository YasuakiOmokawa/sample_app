# Be sure to restart your server when you modify this file.

# SampleApp::Application.config.session_store :cookie_store, key: '_sample_app_session'

# セッションをmemcached で管理
SampleApp::Application.config.session_store ActionDispatch::Session::CacheStore, key: '_foo_session', expire_after: 1.day

