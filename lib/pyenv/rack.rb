#!/usr/bin/env ruby

require "sinatra"

module Pyenv
  class RackApplication < Sinatra::Base
    # GET /descriptorByName/pyenv-PyenvWrapper/ping
    get "/ping" do
      "pong"
    end

    get "/checkVersion" do
      value = params[:value]
      # FIXME: must return hudson.util.FormValidation as response
      if value.nil? or value.to_s.strip.empty?
        "<div class=\"error\">The version string must not be empty.</div>"
      else
        "<div />"
      end
    end
  end
end
