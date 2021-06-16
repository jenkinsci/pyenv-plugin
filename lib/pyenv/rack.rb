#!/usr/bin/env ruby

require "java"
require "sinatra"

module Pyenv
  class RackApplication < Sinatra::Base

    def check_value(value, parameter)
      if value.nil? or value.to_s.strip.empty?
        Java.hudson.util.FormValidation.error("The #{parameter} must not be empty.").renderHtml
      else
        Java.hudson.util.FormValidation.ok().renderHtml
      end
    end

    # GET /descriptorByName/pyenv-PyenvWrapper/ping
    get "/ping" do
      "pong"
    end

    get "/checkVersion" do
      response.body = check_value(params[:value], 'version string')
    end

    get "/checkPyenvRoot" do
      response.body = check_value(params[:value], 'PYENV_ROOT')
    end

    post "/checkVersion" do
      response.body = check_value(params[:value], 'version string')
    end

    post "/checkPyenvRoot" do
      response.body = check_value(params[:value], 'PYENV_ROOT')
    end

  end
end
