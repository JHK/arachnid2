class Arachnid2
  class Typhoeus
    include CachedArachnidResponses
    include Arachnid2::Exoskeleton

    def initialize(url)
      @url = url
      @domain = Adomain[@url]
      @cached_data = []
    end

    def crawl(opts = {})
      preflight(opts)
      typhoeus_preflight

      until @global_queue.empty?
        max_concurrency.times do
          q = @global_queue.shift

          break if @global_visited.size >= crawl_options[:max_urls] || \
                   Time.now > crawl_options[:time_limit] || \
                   memory_danger?

          @global_visited.insert(q)

          request = ::Typhoeus::Request.new(q, request_options)

          data = load_data(@url, opts)
          data.each { |response| yield response } and return unless data.nil?

          request.on_complete do |response|
            @cached_data.push(response)
            links = process(response.effective_url, response.body)
            next unless links

            yield response

            vacuum(links, response.effective_url)
          end

          @hydra.queue(request)
        end # max_concurrency.times do

        @hydra.run

      end # until @global_queue.empty?
      put_cached_data(@url, opts, @cached_data) unless @cached_data.empty?
    ensure
      @cookie_file.close! if @cookie_file
    end # def crawl(opts = {})

    private
      def typhoeus_preflight
        @hydra = ::Typhoeus::Hydra.new(:max_concurrency => max_concurrency)
        typhoeus_proxy_options
      end

      def max_concurrency
        return @max_concurrency if @max_concurrency

        @max_concurrency = "#{@options[:max_concurrency]}".to_i
        @max_concurrency = 1 unless (@max_concurrency > 0)
        @max_concurrency
      end

      def followlocation
        return @followlocation unless @followlocation.nil?

        @followlocation = @options[:followlocation]
        @followlocation = true unless @followlocation.is_a?(FalseClass)
      end

      def request_options
        @cookie_file ||= Tempfile.new('cookies')

        @request_options = {
          timeout: timeout,
          followlocation: followlocation,
          cookiefile: @cookie_file.path,
          cookiejar: @cookie_file.path,
          headers: @options[:headers]
        }.merge(crawl_options[:proxy])

        @request_options[:headers] ||= {}
        @request_options[:headers]['Accept-Language'] ||= DEFAULT_LANGUAGE
        @request_options[:headers]['User-Agent']      ||= DEFAULT_USER_AGENT

        @request_options
      end

      def typhoeus_proxy_options
        crawl_options[:proxy] = {}

        crawl_options[:proxy][:proxy] = "#{@options[:proxy][:ip]}:#{@options[:proxy][:port]}" if @options.dig(:proxy, :ip)
        crawl_options[:proxy][:proxyuserpwd] = "#{@options[:proxy][:username]}:#{@options[:proxy][:password]}" if @options.dig(:proxy, :username)
      end

  end
end
