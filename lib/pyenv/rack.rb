#!/usr/bin/env ruby

require "java"
require "sinatra"

module Pyenv
  class RackApplication < Sinatra::Base
    # GET /descriptorByName/pyenv-PyenvWrapper/ping
    get "/ping" do
      "pong"
    end

    get "/checkVersion" do
      value = params[:value]
      if value.nil? or value.to_s.strip.empty?
        response.body = Java.hudson.util.FormValidation.error("The version string must not be empty.").renderHtml
      else
        response.body = Java.hudson.util.FormValidation.ok().renderHtml
      end
    end
  end
end
