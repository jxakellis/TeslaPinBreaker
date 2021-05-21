gem 'tesla_api'
require 'tesla_api'
require 'rest_client'

#Class used to transform login data to an authToken
class Authorization
  attr_accessor :accessToken
  def initalize()
    header = {
      :content_type => 'application/json',
      :user_agent => '007'
    }
    body = '{
    "grant_type": "password",
    "client_id": "81527cff06843c8634fdc09e8ac0abefb46ac849f38fe1e431c2ef2106796384",
    "client_secret": "c7257eb71a564034f9419ee651c7d0e5f7aa6bfbd18bafb5c5c033b093bb2fa3",
    "email": "xakellis@common-goal.com",
    "password": "Dc4afSEs7Q4faBl!4RpP&7&1"
    }'
    response = RestClient.post 'https://owner-api.teslamotors.com/oauth/token', body, header
    token = response[response.index('access_token')+15.. response.index("token_type") -4]
    @accessToken = token
  end
end

#Authorization should be static, but uses instance variable token to get an authToken used for executing commands
token = Authorization.new()
token.initalize()
authHeader = {
  :authorization => ('Bearer ' + token.accessToken), :user_agent => '007'
}

#produces two objects, beverly and george, with hashes of ids, veh_ids, and display_name
class Vehicle
  attr_accessor :beverly, :george
  def initalize(authHeader)
    vehiclesResponse = RestClient.get 'https://owner-api.teslamotors.com/api/1/vehicles', authHeader

    @beverly = {
      "id" => vehiclesResponse[(vehiclesResponse.index("\"id\":") + 5).. (vehiclesResponse.index("veh")-3)],
      "vehicle_id" => vehiclesResponse[vehiclesResponse.index("vehicle_id")+12.. vehiclesResponse.index("vin")-3],
      "display_name" => vehiclesResponse[vehiclesResponse.index("display_name")+15.. vehiclesResponse.index("option_codes")-4],
      "id_s" => vehiclesResponse[vehiclesResponse.index("id_s")+7.. vehiclesResponse.index("calendar_enabled")-4],
    }
    secondStart = (vehiclesResponse.index("},{") +3)
    @george = {
      "id" => vehiclesResponse[(vehiclesResponse.index("\"id\":", secondStart) + 5).. (vehiclesResponse.index("veh", secondStart)-3)],
      "vehicle_id" => vehiclesResponse[vehiclesResponse.index("vehicle_id", secondStart)+12.. vehiclesResponse.index("vin", secondStart)-3],
      "display_name" => vehiclesResponse[vehiclesResponse.index("display_name", secondStart)+15.. vehiclesResponse.index("option_codes", secondStart)-4],
      "id_s" => vehiclesResponse[vehiclesResponse.index("id_s", secondStart)+7.. vehiclesResponse.index("calendar_enabled", secondStart)-4],
    }
  end
end

#Prints out information about each car, vehicles should be a static class but idk how to do that in ruby
vehicles = Vehicle.new()
vehicles.initalize(authHeader)
puts "token - " + token.accessToken
puts "id_s - " + vehicles.beverly["id_s"]
puts "id - " + vehicles.beverly["id"]
puts "vehicle_id - " + vehicles.beverly["vehicle_id"]
puts "display_name - " + vehicles.beverly["display_name"]
puts "id_s - " + vehicles.george["id_s"]
puts "id - " + vehicles.george["id"]
puts "vehicle_id - " + vehicles.george["vehicle_id"]
puts "display_name - " + vehicles.george["display_name"]

#Uses the tesla_api to create two instances for each car, each instance can be used to call api specific methods for the car used
tesla_api = TeslaApi::Client.new(access_token: token.accessToken)
model_3 = tesla_api.vehicles.last
model_s = tesla_api.vehicles.first
targetModel = model_3
targetModel.wake_up
pinFound = false

#A loop that tries every pin from 0000 to 9999 if the selected car is in SLM, if it gets a match it puts the result then turns SLM back on & exits the whole loop
1.times do |a|
  a=6
  break if (pinFound == true)
  1.times do |b|
    break if (pinFound == true)
    10.times do |c|
      break if (pinFound == true)
      10.times do |d|
        num = ((a).to_s + (b).to_s + (c).to_s + (d).to_s)
        if ((targetModel.deactivate_speed_limit(num))["result"] == true)
          puts "SLM Pin: #{num.to_s}"
          pinFound = true
          targetModel.activate_speed_limit(num)
        end
      end
    end
  end
end
