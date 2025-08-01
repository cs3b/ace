# frozen_string_literal: true

require "json"
require "net/http"
require "fileutils"

module CodingAgentTools
  # PricingFetcher handles fetching and caching of LiteLLM pricing data
  # This is inspired by ccusage@15.2.0 which successfully uses LiteLLM as authoritative pricing source
  class PricingFetcher
    # LiteLLM pricing API endpoint - same source as ccusage uses
    LITELLM_PRICING_URL = "https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json"

    # Default cache directory for pricing data
    DEFAULT_CACHE_DIR = File.expand_path("~/.coding-agent-tools-cache")

    # Cache file for pricing data
    PRICING_CACHE_FILE = "litellm_pricing.json"

    # Cache expiration time (24 hours in seconds)
    CACHE_EXPIRATION = 24 * 60 * 60

    # Pricing data structure keys that LiteLLM uses
    PRICING_FIELDS = %w[
      input_cost_per_token
      output_cost_per_token
      cache_creation_input_token_cost
      cache_read_input_token_cost
    ].freeze

    class PricingError < StandardError; end

    class NetworkError < PricingError; end

    class CacheError < PricingError; end

    def initialize(cache_dir: DEFAULT_CACHE_DIR)
      @cache_dir = cache_dir
      @cache_file_path = File.join(@cache_dir, PRICING_CACHE_FILE)
      @pricing_data = nil
    end

    attr_reader :cache_dir, :cache_file_path

    # Fetch pricing data with automatic fallback to cache
    # @param force_refresh [Boolean] Force refresh from API even if cache is valid
    # @return [Hash] LiteLLM pricing data
    # @raise [PricingError] If both API and cache fail
    def fetch_pricing_data(force_refresh: false)
      return @pricing_data if @pricing_data && !force_refresh

      if force_refresh || cache_expired?
        begin
          @pricing_data = fetch_from_api
          save_to_cache(@pricing_data)
        rescue NetworkError => e
          # Fallback to cache if API fails
          raise PricingError, "API failed and no cache available: #{e.message}" unless cache_exists?

          @pricing_data = load_from_cache
        end
      else
        @pricing_data = load_from_cache
      end

      @pricing_data
    end

    # Get pricing data for a specific model with fuzzy matching
    # Implements ccusage-style model name matching
    # @param model_id [String] Model identifier (e.g., "claude-3-5-sonnet", "anthropic/claude-3-5-sonnet")
    # @return [Hash, nil] Pricing data for the model, nil if not found
    def get_model_pricing(model_id)
      pricing_data = fetch_pricing_data

      # Direct match first
      return pricing_data[model_id] if pricing_data.key?(model_id)

      # Fuzzy matching - try different variations like ccusage does
      find_model_with_fuzzy_matching(model_id, pricing_data)
    end

    # Check if pricing data contains a model
    # @param model_id [String] Model identifier
    # @return [Boolean] True if model pricing is available
    def has_model_pricing?(model_id)
      !get_model_pricing(model_id).nil?
    end

    # Get list of all available models in pricing data
    # @return [Array<String>] List of model identifiers
    def available_models
      fetch_pricing_data.keys.sort
    end

    # Force refresh of pricing data from API
    # @return [Hash] Fresh pricing data
    def refresh!
      fetch_pricing_data(force_refresh: true)
    end

    # Get cache metadata
    # @return [Hash] Cache information including age and path
    def cache_info
      {
        exists: cache_exists?,
        path: @cache_file_path,
        age_hours: cache_age_hours,
        expired: cache_expired?,
        size_bytes: cache_exists? ? File.size(@cache_file_path) : 0
      }
    end

    private

    # Fetch pricing data from LiteLLM API
    # @return [Hash] Pricing data from API
    # @raise [NetworkError] If API request fails
    def fetch_from_api
      uri = URI(LITELLM_PRICING_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30

      response = http.get(uri.path)

      unless response.code == "200"
        raise NetworkError, "API request failed with status #{response.code}: #{response.message}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise NetworkError, "Invalid JSON response from API: #{e.message}"
    rescue => e
      raise NetworkError, "Network error: #{e.message}"
    end

    # Save pricing data to cache file
    # @param data [Hash] Pricing data to save
    # @raise [CacheError] If save operation fails
    def save_to_cache(data)
      FileUtils.mkdir_p(@cache_dir)

      cache_payload = {
        cached_at: Time.now.utc.iso8601,
        pricing_data: data
      }

      File.write(@cache_file_path, JSON.pretty_generate(cache_payload))
    rescue => e
      raise CacheError, "Failed to save cache: #{e.message}"
    end

    # Load pricing data from cache file
    # @return [Hash] Cached pricing data
    # @raise [CacheError] If cache load fails
    def load_from_cache
      raise CacheError, "Cache file does not exist: #{@cache_file_path}" unless cache_exists?

      cache_content = JSON.parse(File.read(@cache_file_path))
      cache_content["pricing_data"]
    rescue JSON::ParserError => e
      raise CacheError, "Invalid JSON in cache file: #{e.message}"
    rescue => e
      raise CacheError, "Failed to load cache: #{e.message}"
    end

    # Check if cache file exists
    # @return [Boolean] True if cache exists
    def cache_exists?
      File.exist?(@cache_file_path)
    end

    # Check if cache has expired
    # @return [Boolean] True if cache is expired or doesn't exist
    def cache_expired?
      return true unless cache_exists?

      cache_age_hours > CACHE_EXPIRATION / 3600.0
    end

    # Get cache age in hours
    # @return [Float] Cache age in hours, 0 if cache doesn't exist
    def cache_age_hours
      return 0.0 unless cache_exists?

      (Time.now - File.mtime(@cache_file_path)) / 3600.0
    end

    # Fuzzy model matching implementation (inspired by ccusage)
    # @param model_id [String] Model to find
    # @param pricing_data [Hash] All pricing data
    # @return [Hash, nil] Pricing data if found
    def find_model_with_fuzzy_matching(model_id, pricing_data)
      # Try provider prefixes - many models are listed with provider/ prefix
      provider_variations = generate_provider_variations(model_id)

      provider_variations.each do |variation|
        return pricing_data[variation] if pricing_data.key?(variation)
      end

      # Try partial matching for model names
      find_partial_model_match(model_id, pricing_data)
    end

    # Generate provider prefix variations
    # @param model_id [String] Base model identifier
    # @return [Array<String>] List of variations to try
    def generate_provider_variations(model_id)
      variations = []

      # Try common provider prefixes
      providers = %w[anthropic openai google mistralai meta-llama together_ai]

      providers.each do |provider|
        variations << "#{provider}/#{model_id}"

        # Also try with some provider-specific transformations
        case provider
        when "anthropic"
          # Many Claude models are listed as anthropic/claude-X
          variations << "#{provider}/claude-#{model_id}" unless model_id.start_with?("claude")
        when "openai"
          # GPT models sometimes listed as openai/gpt-X
          variations << "#{provider}/gpt-#{model_id}" unless model_id.start_with?("gpt")
        end
      end

      variations
    end

    # Find partial model name matches
    # @param model_id [String] Model to find
    # @param pricing_data [Hash] All pricing data
    # @return [Hash, nil] Pricing data if found
    def find_partial_model_match(model_id, pricing_data)
      # Look for models that contain the model_id as substring
      normalized_model_id = model_id.downcase.gsub(/[-_]/, "")

      pricing_data.each do |key, value|
        normalized_key = key.downcase.gsub(/[-_]/, "")

        # Check if the model name contains our search term
        return value if normalized_key.include?(normalized_model_id) || normalized_model_id.include?(normalized_key)
      end

      nil
    end
  end
end
