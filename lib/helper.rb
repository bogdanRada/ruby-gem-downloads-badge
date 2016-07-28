require 'color/css'
# module that is used for formatting numbers using metrics
module Helper
# function that makes the methods incapsulated as utility functions

COLOR_SCHEME = {
  "brightgreen" =>   { "colorB" => "#4c1" },
  "green"       =>   { "colorB" =>  "#97CA00" },
  "yellow"      =>   { "colorB" => "#dfb317" },
  "yellowgreen" =>   { "colorB" => "#a4a61d" },
  "orange"      =>   { "colorB" => "#fe7d37" },
  "red"         =>   { "colorB" => "#e05d44" },
  "blue"        =>   { "colorB" => "#007ec6" },
  "grey"        =>   { "colorB" => "#555" },
  "gray"        =>   { "colorB" => "#555" },
  "lightgrey"   =>   { "colorB" => "#9f9f9f" },
  "lightgray"   =>   { "colorB" => "#9f9f9f" }
}

module_function

delegate :settings, :cookie_hash, :set_time_zone , to: :RubygemsDownloadShieldsApp
delegate :logger,:request_cookies, to: :settings

def root
  File.expand_path(File.dirname(__dir__))
end

# Returns the display_type from the params , otherwise nil
#
# @return [String, nil] Returns the display_type  from the params , otherwise nil
def display_type
  @params.fetch('type', nil)
end

def fetch_content_type(extension = 'svg')
  extension = extension.present? && available_extension?(extension) ? extension : 'svg'
  mime_type = Rack::Mime::MIME_TYPES[".#{extension}"]
  "#{mime_type};Content-Encoding: gzip; charset=utf-8;"
end

def available_extension?(extension)
  ['png', 'svg'].include?(extension)
end

def fetch_color_hex(name)
  return COLOR_SCHEME[name]['colorB'] if COLOR_SCHEME[name]
  if name.starts_with?('#')
    name
  else
    Color::CSS[name].html
  end
end

def clean_image_label(label)
  return if label.blank?
  label.gsub(/[\s]+/, ' ').gsub(/[\_\-]+/, '_')
end


# Returns utf8 encoding of the msg
# @param [String] msg
# @return [String] ReturnsReturns utf8 encoding of the msg
def force_utf8_encoding(msg)
  msg.respond_to?(:force_encoding) && msg.encoding.name != 'UTF-8' ? msg.force_encoding('UTF-8') : msg
end

# Method that checks if we need to display the total downloads
#
# @return [Boolean] Returns true if we need to display the total downloads
def display_total
  display_type.present? && display_type == 'total'
end

# The prefixes that can be used in metric display
#
# @return [Array<String>] Returns the metric prefixes array that can be used in metric display
def metric_prefixes
  %w(k M G T P E Z Y)
end

# Dispatches the response either to the final callback or to the block that will use the response
# and then call the callback
#
# @param [String] res The response string that will be dispatched
# @param [Hash] options The callback that is used to dispatch further the response
# @param [Proc] block The block that is used for parsing response and then calling the callback
# @return [void]
def dispatch_http_response(res, options, &block)
  callback = options.fetch('callback', nil)
  (res.blank? && callback.present?) ? callback.call(res) : block.call(res)
end

# Returns the metric powers of all metric prefixes . This method is used in metric display of numbers
# @see #metric_prefixes
# @return [Array<Number>] An array of metric powers that correspont to each metric prefix
def metric_power
  metric_prefixes.map.with_index { |_item, index| (1000**(index + 1)).to_i }
end

# Method that is used to parse a string as JSON , if it fails will return nil
# @see JSON#parse
# @param [string] res The string that will be parsed as JSON
# @return [Hash, nil] Returns Hash object if the json parse succeeds or nil otherwise
def parse_json(res)
  return if res.blank?
  JSON.parse(res)
rescue JSON::ParserError
  nil
end

# Method that is used to print to a stream . If the stream is already closed will return nil
# otherwise will append the response to the stream and close the stream
#
# @param [String] response THe string that will be appended to the stream
# @param [Sinatra::Stream] output_buffer The sinatra stream that will be used to append information
# @return [nil] The method will return nil even if is success or not, the only thing that is affected is the stream
def print_to_output_buffer(response, output_buffer)
  return if output_buffer.closed?
  output_buffer << response
  output_buffer.close
end

# Method that tries to check if the version provided is a valid versin sintactical and semantical.
# it does not check if the gem actually has that version published or not.
# if the parsing of the version fails will return nil, otherwise will return the parsed version
# @see Versionomy#parse
# @param [String] gem_version The string that represents the gem version that we want to check
# @return [String, nil] Returns nil if the version is blank or 'stable' or the parsing has failed, otherwise will return the parsed version
def parse_gem_version(gem_version)
  return if gem_version.blank? || gem_version == 'stable'
  Versionomy.parse(gem_version)
rescue Versionomy::Errors::ParseError
  return nil
end

# Given an aray of gem versions , will filter them and return only the stable versions
#
# @param [Array<Hash>] http_response The HTTP response as a array of Hash
# @return [Array<Hash>] Will return only the items from the array that have the key 'prerelease' with value false
def stable_gem_versions(http_response)
  http_response.blank? ? [] : http_response.select { |val| val['prerelease'] == false }
end

# method that will return nil if the array of versions is empty or will return the versions sorted
#
# @param [Array<Hash>] versions The versions that have to be sorted
# @return [Array<String>] Will return nil if the array is blank or will return an array with only the version numbers sorted
def sorted_versions(versions)
  versions.blank? ? [] : versions.map { |val| val['number'] }.version_sort
end

# Method to search for a version number in all gem versions and return the hash object
#
# @param [Array<Hash>] versions The array of gem versions that we will use for searching
# @param [string] number The version number used for searching
# @return [Hash] Returns the version object that has the number specified
def find_version(versions, number)
  number.blank? ? {} : versions.find { |val| val['number'] == number }
end

# Method that is used to return the last item from an array of strings.
# Will return empty string if array is blank
#
# @param [Array<String>] sorted_versions describe sorted_versions
# @return [string] description of returned object
def last_version(sorted_versions)
  sorted_versions.blank? ? '' : sorted_versions.last
end

# Method that is used to filter the versions, sort them and find the latest stable version
# @see #stable_gem_versions
# @see #sorted_versions
# @see #last_version
# @see #find_version
#
# @param [Array<Hash>] http_response The array with all the versions of the gem
# @return [Hash] Returns the latest stable version
def get_latest_stable_version_details(http_response)
  versions = stable_gem_versions(http_response)
  sorted_versions = sorted_versions(versions)
  last_version_number = last_version(sorted_versions)
  find_version(versions, last_version_number)
end
end
