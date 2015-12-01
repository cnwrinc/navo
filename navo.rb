#!/usr/bin/env ruby

require 'pp'
require 'nokogiri'
require 'victor_ops/client'
require 'sinatra/base'
require 'sinatra/config_file'


class NaVo < Sinatra::Base
  enable :logging, :dump_errors, :raise_errors
  register Sinatra::ConfigFile
  config_file './navo.yaml'


  url = "#{settings.url}#{settings.apikey}"

  routingkey = settings.routingkey

  client = VictorOps::Client.new api_url: url, routing_key: routingkey
  client.monitoring_tool="NaVo Bridge"

	get '/' do
		client.info message: 'Testing 123', monitoring_tool: 'N-Able Alert'
		'Nothing to see here'
	end
	post '/' do
	  @body=request.body.read
    @doc = Nokogiri::XML(@body)
    @statetag = @doc.at_xpath("//QualitativeNewState")
    @state = @statetag.text
    @entitytag = @doc.at_xpath("//TaskIdent")
    @customertag = @doc.at_xpath("//CustomerName")
    @devicetag = @doc.at_xpath("//DeviceName")
    @servicetag = @doc.at_xpath("//AffectedService")
    @customer = @customertag.text
    @entity = @entitytag.text
    @device = @devicetag.text
    @service = @servicetag.text

    @statedetailtag = @doc.at_xpath("//QuantitativeNewState")
    @statedetail = @statedetailtag.text
    @displayname = "#{@customer} - #{@device} - #{@service} is #{@state}"
    @entityid = "#{@customer}:#{@entity}"

    logger.info("Received alert: #{@entity} - #{@state}")
    client.entity_display_name=@displayname
    case @state
    when "Failed"
      client.critical message: @statedetail, state_message: @statedetail, entity_id: @entityid
    when "Normal"
      client.recovery message: @statedetail, state_message: @statedetail, entity_id: @entityid
    when "Warning"
      client.warn message: @statedetail, state_message: @statedetail, entity_id: @entityid
    else
		  client.info message: @statedetail, state_message: @statedetail, entity_id: @entityid
    end
		''
	end
end
