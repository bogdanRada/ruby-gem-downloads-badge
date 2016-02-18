$stdout.sync = true
$stderr.sync = true
require 'rubygems'
require "bundler"
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym
require 'active_support/all'
require 'thread'
require 'celluloid'
require 'celluloid/autostart'
require 'json'
require 'securerandom'
require 'versionomy'
require 'typhoeus'
::Logger.class_eval do
  alias_method :write, :<<
  alias_method :puts, :<<
end


Dir.glob("./config/initializers/**/*.rb") {|file| require file}
Dir.glob("./lib**/*.rb") {|file| require file}



module Resources
  class Home <Webmachine::Resource
    include Logging

    def self.request_cookies
      Thread.current[:request_cookies] ||= {}
    end

    def self.cookie_hash
      CookieHash.new.tap { |hsh|
        request_cookies[url].uniq.each { |c| hsh.add_cookies(c) }
      }
    end

    def self.set_time_zone
      Time.zone = 'UTC'
      ENV['TZ'] = 'UTC'
    end

    def allowed_methods
      [ "GET"]
    end

    def encodings_provided
      { 'gzip' => :encode_gzip,
        'deflate' => :encode_deflate,
        'identity' => :encode_identity }
      end

      def content_types_provided
        [["image/svg+xml", :to_svg]]
      end

      def resource_exists?
        true
      end


      def params
        {
          'gem' => request.path_info[:gem],
          'version' => request.path_info[:version],
          'extension' =>  request.path_info[:extension]
        }.merge(request.query).stringify_keys
      end

      def display_favicon?
        params["gem"].present? &&  params["gem"].include?("favicon")
      end

      def public_folder
        File.expand_path('../../../static', __FILE__)
      end

      def set_content_type
        params[:extension] = params.fetch('extension', 'svg')
        mime_type = Rack::Mime::MIME_TYPES[".#{params['extension']}"]
        "#{mime_type};Content-Encoding: gzip; charset=utf-8;"
      end

      def finish_request
        response.headers['Pragma'] = "no-cache"
        response.headers['Cache-Control'] = "no-cache, must-revalidate, max-age=-1"
        response.headers['Expires'] = Time.now - 1
        unless display_favicon?
          #  response.headers['Content-Type'] =  set_content_type
        end
      end

      def to_svg
        if display_favicon?
          response.headers['Content-Type'] = "image/x-icon; Content-Encoding: gzip; charset=utf-8;"
          response.headers['Content-Disposition'] = "inline"
          @file = File.join(public_folder, "favicon.ico")
          open(@file, "rb") {|io| io.read }
        else
          @condition = Celluloid::Condition.new
          @worker_supervisor = Celluloid::SupervisionGroup.run!
          blk = lambda do |downloads|
            original_params = request.query
            @worker_supervisor.supervise_as(:badge_downloader, BadgeApi, params.merge('request_name' => params[:gem]), original_params, @condition ,  downloads)
          end
          @worker_supervisor.supervise_as(:rubygems_api, RubygemsApi, params, blk)
        end
        wait_result = @condition.wait
        raise wait_result
      end


    end
  end
