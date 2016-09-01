require 'rubygems'
require 'rest-client'
require 'json'

# define program-wide variables
# https://devcentral.f5.com/codeshare/ruby-virtual-server-and-pool-creation
BIGIP_ADDRESS = '142.107.185.43'
BIGIP_USER = 'admin'
BIGIP_PASS = 'your-best-guess'

SLEEP_TIME = 20

VS_NAME = 'test-http-virtual_ruby'
VS_ADDRESS = '142.107.186.43'
VS_PORT = '80'

POOL_NAME = 'test-http-pool_ruby'
POOL_LB_METHOD = 'least-connections-member'
POOL_MEMBERS = [ '100.100.104.100:80' ]

# create/delete methods
def create_pool bigip, name, members, lb_method
  # convert member format
  members.collect { |member| { :kind => 'ltm:pool:members', :name => member} }

  # define test pool
  payload = {
      :kind => 'tm:ltm:pool:poolstate',
      :name => name,
      :description => 'A Ruby rest-client test pool',
      :loadBalancingMode => lb_method,
      :monitor => 'http',
      :members => members
  }

  bigip['ltm/pool'].post payload.to_json
end

def create_http_virtual bigip, name, address, port, pool
  # define test virtual
  payload = {
      :kind => 'tm:ltm:virtual:virtualstate',
      :name => name,
      :description => 'A Ruby rest-client test virtual server',
      :destination => "#{address}:#{port}",
      :mask => '255.255.255.255',
      :ipProtocol => 'tcp',
      :sourceAddressTranslation => { :type => 'automap' },
      :profiles => [
          { :kind => 'ltm:virtual:profile', :name => 'http' },
          { :kind => 'ltm:virtual:profile', :name => 'tcp' }
      ],
      :pool => pool
  }

  bigip['ltm/virtual'].post payload.to_json
end

def delete_pool bigip, name
  url = "ltm/pool/#{name}"
  bigip[url].delete
end

def delete_virtual bigip, name
  url = "ltm/virtual/#{name}"
  bigip[url].delete
end

# REST resource for BIG-IP that all other requests will use
bigip = RestClient::Resource.new(
    "https://#{BIGIP_ADDRESS}/mgmt/tm/",
    :user => BIGIP_USER,
    :password => BIGIP_PASS,
    :verify_ssl => false,
    :headers => { :content_type => 'application/json' }
)
puts "created REST resource for BIG-IP at #{BIGIP_ADDRESS}..."

# create pool
create_pool bigip, POOL_NAME, POOL_MEMBERS, POOL_LB_METHOD
puts "created pool \"#{POOL_NAME}\" with members #{POOL_MEMBERS.join(', ')}..."

# create virtual
create_http_virtual bigip, VS_NAME, VS_ADDRESS, VS_PORT, POOL_NAME
puts "created virtual server \"#{VS_NAME}\" with destination #{VS_ADDRESS}:#{VS_PORT}..."

# sleep for a little while
puts "sleeping for #{SLEEP_TIME} seconds, check for successful creation..."
sleep SLEEP_TIME

# delete virtual
#delete_virtual bigip, VS_NAME
#puts "deleted virtual server \"#{VS_NAME}\"..."

# delete pool
#delete_pool bigip, POOL_NAME
#puts "deleted pool \"#{POOL_NAME}\"..."
#puts "deleted pool \"#{POOL_NAME}\"..."