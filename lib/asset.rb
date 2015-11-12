require_relative './helper'
# class used for connecting to runygems.org and downloading info about a gem
class Asset
  include Helper

  def self.environment(app_settings)
    env = Sprockets::Environment.new app_settings.root
    env.append_path app_settings.public_folder
    env.js_compressor  = :uglify
    if app_settings.development?
      env.cache = nil
    else
      uid = Digest::MD5.hexdigest(File.dirname(__FILE__))[0, 8]
      env.cache = Sprockets::Cache::FileStore.new("/tmp/sinatra-#{uid}")
    end
    env.logger = Logger.new(STDOUT)
    env
  end

end
