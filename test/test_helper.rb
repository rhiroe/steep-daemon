# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "steep/daemon"
require "steep/daemon/cli"

require "minitest/autorun"
