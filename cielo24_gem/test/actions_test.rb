require 'test/unit'
require '../lib/cielo24/actions'
require './configuration'


class ActionsTest < Test::Unit::TestCase

  def initialize(opts)
    super(opts)
    @config = Configuration.new
    @actions = Cielo24::Actions.new(@config.server_url)
    @api_token = nil
    @secure_key = nil
  end

  def setup
    # Start with a fresh session each time
    @api_token = @actions.login(@config.username, @config.password, nil, true)
    @secure_key = @actions.generate_api_key(@api_token, @config.username, false)
  end

  def teardown
    # Remove secure key
    unless @api_token.nil? or @secure_key.nil?
      begin
        @actions.remove_api_key(@api_token, @secure_key)
      rescue WebError => e
        if e.type == ErrorType::ACCOUNT_UNPRIVILEGED
          @api_token = @actions.login(@config.username, @config.password, nil, true)
          @actions.remove_api_key(@api_token, @secure_key)
        else
          # Pass silently
        end
      end
    end
  end
end