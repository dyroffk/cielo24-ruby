module Cielo24
  class WebUtils

    require 'json'
    require 'httpclient'
    require 'timeout'
    require 'logger'
    require 'tzinfo'
    include JSON
    include TZInfo

    BASIC_TIMEOUT = 60           # seconds (1 minute)
    DOWNLOAD_TIMEOUT = 300       # seconds (5 minutes)
    UPLOAD_TIMEOUT = 60*60*24*7  # seconds (1 week)
    SERVER_TZ = 'America/Los_Angeles'
    LOGGER = Logger.new(STDOUT)

    def self.get_json(uri, method, timeout, query=nil, headers=nil, body=nil)
      response = http_request(uri, method, timeout, query, headers, body)
      return JSON.parse(response)
    end

    def self.http_request(uri, method, timeout, query=nil, headers=nil, body=nil)
      http_client = HTTPClient.new
      http_client.cookie_manager = nil
      http_client.send_timeout = UPLOAD_TIMEOUT
      LOGGER.info(uri + (query.nil? ? '' : '?' + URI.encode_www_form(query)))

      # Timeout block:
      begin
        # Error is raised if the following block fails to execute in 'timeout' sec:
        Timeout.timeout(timeout) { # nil timeout = infinite

          response = http_client.request(method, uri, query, body, headers, nil)
          # Handle web errors
          if response.status_code == 200 or response.status_code == 204
            return response.body
          else
            json = json_parse(response.body)
            raise WebError.new(response.status_code, json['ErrorType'], json['ErrorComment'])
          end

        }
      rescue Timeout::Error
        raise TimeoutError.new('The HTTP session has timed out.')
      end
    end

    def self.to_utc(s)
      return s if s.empty?
      tz = Timezone.get(SERVER_TZ)
      local = DateTime.iso8601(s)
      utc = tz.local_to_utc local
      format = '%Y-%m-%dT%H:%M:%S.%L%z' # iso8601 with milliseconds
      utc.strftime(format)
    end

    def self.json_parse(s)
      begin
        return JSON.parse(s)
      rescue JSON::ParserError
        raise CieloError.new('PARSING_ERROR', "Response: #{s}")
      end
    end
  end

  class CieloError < StandardError
    attr_reader :type
    def initialize(type, comment)
      super(comment)
      @type = type
    end
  end

  class WebError < CieloError
    attr_reader :status_code
    def initialize(status_code, type, comment)
      super(type, comment)
      @status_code = status_code
    end

    def to_s
      "#{@status_code}:#{@type} - #{super.to_s}"
    end
  end

  class TimeoutError < CieloError
    def initialize(message)
      super('TIMEOUT_ERROR', message)
    end
  end
end