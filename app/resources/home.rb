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

    def self.cookie_hash(url)
      CookieHash.new.tap { |hsh|
        request_cookies[url].uniq.each { |c| hsh.add_cookies(c) }
      }
    end

    QUEUES = Concurrent::Map.new do |hash, queue_name| #:nodoc:
      hash.compute_if_absent(queue_name) {
        Concurrent::ThreadPoolExecutor.new(
          min_threads: 10, # create 10 threads at startup
          max_threads: 50, # create at most 50 threads
          max_queue: 0, # unbounded queue of work waiting for an available thread
          )
      }
    end

    BADGES_QUEUES = Concurrent::Map.new do |hash, queue_name| #:nodoc:
      hash.compute_if_absent(queue_name) {
        Concurrent::ThreadPoolExecutor.new(
          min_threads: 10, # create 10 threads at startup
          max_threads: 50, # create at most 50 threads
          max_queue: 0, # unbounded queue of work waiting for an available thread
          )
      }
    end

     def enqueue_badge(*args) #:nodoc:
      options = args.extract_options!
      BADGES_QUEUES[options.fetch(:queue, 'default')].post(args) { |job|
        BadgeApi.spawn(name:"badge_api#{SecureRandom.uuid}", args: [*job])
      }
    end

    def enqueue(*args) #:nodoc:
      options = args.extract_options!
      QUEUES[options.fetch(:queue, 'default')].post(args) { |job|
        RubygemsApi.spawn(name: "rubygems_api_#{SecureRandom.uuid}", args: [*job])
      }
    end


    def self.badge_workers
      @@badge_workers ||= worker_supervisor.pool(BadgeApi, as: :badge_workers, size: 10)
    end 

    def self.set_time_zone
      Time.zone = 'UTC'
      ENV['TZ'] = 'UTC'
    end

    def fetch_mime_type
      Rack::Mime::MIME_TYPES[".#{params['extension']}"]
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
        [[fetch_mime_type, :to_svg]]
      end

      def resource_exists?
        true
      end


      def params
        {
          'gem' => request.path_info[:gem],
          'version' => request.path_info[:version],
          'extension' =>  request.path_info[:extension] || 'svg'
          }.merge(request.query).stringify_keys
        end

        def display_favicon?
          params["gem"].present? &&  params["gem"].include?("favicon")
        end

        def public_folder
          File.expand_path('../../../static', __FILE__)
        end

        def set_content_type
          "#{fetch_mime_type};Content-Encoding: gzip; charset=utf-8;"
        end

        def finish_request
          response.headers['Pragma'] = "no-cache"
          response.headers['Cache-Control'] = "no-cache, must-revalidate, max-age=-1"
          response.headers['Expires'] = Time.now - 1
          unless display_favicon?
            response.headers['Content-Type'] =  set_content_type
          end
        end


        def to_svg
          if display_favicon?
            response.headers['Content-Type'] = "image/x-icon; Content-Encoding: gzip; charset=utf-8;"
            response.headers['Content-Disposition'] = "inline"
            @file = File.join(public_folder, "favicon.ico")
            open(@file, "rb") {|io| io.read }
          else
            response.body = ""
            condition = Concurrent::Event.new
              blk = lambda do |downloads|
                original_params = request.query
                enqueue_badge(params.merge('request_name' => params[:gem]), original_params, response.body ,  downloads, condition)
              end
              enqueue(params, blk)
             condition.wait
            end
          end



        end
      end
