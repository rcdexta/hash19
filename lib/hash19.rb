require 'hash19/version'
require 'hash19/lazy'
require 'hash19/core_helpers'
require 'hash19/resolvers'
require 'hash19/core'
require 'active_support/all'
require 'jsonpath'

module Hash19
  extend ActiveSupport::Concern
  include Core
end
