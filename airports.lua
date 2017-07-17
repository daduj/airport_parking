redis.replicate_commands()
local input = redis.call("get", KEYS[1])
local key = KEYS[1]
local plane_id = ARGV[1]
local plane_id_to_num = tonumber(plane_id)

--Lets check if user entered a valid id of a plane
if plane_id_to_num ~= nil and plane_id_to_num > 0 and plane_id_to_num < 81 then

	local parking_spots_key_exist = redis.call("EXISTS", "parking_spots")
	local asigned_spots_key_exist = redis.call("EXISTS", "asigned_spots")
	local parking_spots --Holds ids of all availible parking spots
	local asigned_spots = {} --Holds ids of asigned airplanes and their parking spots
	local return_asigned_spot_id --If all goes well, we will return this variable at the end (parking spot id)

	--If we dont have parking spots yet, we must create them
	if parking_spots_key_exist == 0 then
		for i=1,90 do
			redis.call("SADD", "parking_spots", i)
		end
	end

	--If no asigned spots yet, we will set empty key in redis
	if asigned_spots_key_exist == 0 then
		redis.call("SET", "asigned_spots", cjson.encode(asigned_spots))
	end

	parking_spots = redis.call("SMEMBERS", "parking_spots")
	asigned_spots = cjson.decode(redis.call("GET", "asigned_spots"))

	--Now we shall see if our airplane already has a parking spot
	if asigned_spots[plane_id] then
		--Yes, we will later return that parking spot id
		return_asigned_spot_id = asigned_spots[plane_id]
	else
		--Now we are getting random parking spot id from available parking spots
		local rand_parking_spot_id = redis.call("SPOP", "parking_spots")
		asigned_spots[plane_id] = rand_parking_spot_id --Asign it to plane id
		return_asigned_spot_id = rand_parking_spot_id --We will return newly asigned parking id
		redis.call("SET", "asigned_spots", cjson.encode(asigned_spots)) --Saving asigned spot for plane to redis
	end

	return return_asigned_spot_id --Thats it!

else
	--User entered invalid id of a plane
	return "Invalid id of the plane"
end
