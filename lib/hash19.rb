require 'hash19/version'
require 'hash19/core'
require 'active_support/all'

module Hash19
  extend ActiveSupport::Concern
  include Core
end
