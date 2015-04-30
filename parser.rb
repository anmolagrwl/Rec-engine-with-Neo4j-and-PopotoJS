require 'rubygems'
require 'json'

string = File.read('koramangala.json')
parsed = JSON.parse(string)

foods = parsed["food"]

foods.each{|food|
	name = food["name"]
	lat = food["geometry"]["location"]["lat"]
	lng = food["geometry"]["location"]["lng"]
	# p "#{name} #{lat} #{lng}"
	address = food["address"]
	rating = food["rating"]
	comments = food["comments"]
	comments.each{ |comment|
		comment
	}
}

educations = parsed["education"]

educations.each{|education|
	name = education["name"]
	lat = education["geometry"]["location"]["lat"]
	lng = education["geometry"]["location"]["lng"]
	# p "#{name} #{lat} #{lng}"
	address = education["address"]
	rating = education["rating"]
	comments = education["comments"]
	comments.each{ |comment|
		comment
	}
}

healthcares = parsed["healthcare"]

healthcares.each{|healthcare|
	name = healthcare["name"]
	lat = healthcare["geometry"]["location"]["lat"]
	lng = healthcare["geometry"]["location"]["lng"]
	# p "#{name} #{lat} #{lng}"
	address = healthcare["address"]
	rating = healthcare["rating"]
	comments = healthcare["comments"]
	comments.each{ |comment|
		comment
	}
}