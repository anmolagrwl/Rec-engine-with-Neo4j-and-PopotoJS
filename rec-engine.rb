require 'neo4j-core'
require 'rubygems'
require 'json'
require 'open-uri'
require 'sentimental'

# Using Neo4j Server Cypher Database
session = Neo4j::Session.open(:server_db)

def run_recommend (file, area)
string = File.read(file)
parsed = JSON.parse(string)

area1 = Neo4j::Node.create({name: area}, :area)
puts "Created node #{area1[:name]} with labels #{area1.labels.join(', ')}"

foods = parsed["food"]
foods.each{|food|
	name = food["name"]
	lat = food["geometry"]["location"]["lat"]
	lng = food["geometry"]["location"]["lng"]
	# p "#{name} #{lat} #{lng}"
	address = food["address"]
	rating = food["rating"]

	node1 = Neo4j::Node.create({name: name, latitude: lat, longitude: lng, address: address, rating: rating}, :food)

	rel1 = area1.create_rel(:has_food_option, node1)
	
	comments = food["comments"]
	comments.each{ |comment|
		node2 = Neo4j::Node.create({comment: comment}, :comment)
		rel2 = node1.create_rel(:has_food_option_comment, node2)
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

	node3 = Neo4j::Node.create({name: name, latitude: lat, longitude: lng, address: address, rating: rating}, :education)

	rel3 = area1.create_rel(:has_education_option, node3)

	comments = education["comments"]
	comments.each{ |comment|
		node4 = Neo4j::Node.create({comment: comment}, :comment)
		rel4 = node3.create_rel(:has_education_option_comment, node4)
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

	node5 = Neo4j::Node.create({name: name, latitude: lat, longitude: lng, address: address, rating: rating}, :healthcare)

	rel5 = area1.create_rel(:has_healthcare_option, node5)

	comments = healthcare["comments"]
	comments.each{ |comment|
		node6 = Neo4j::Node.create({comment: comment}, :comment)
		rel6 = node5.create_rel(:has_healthcare_option_comment, node6)
	}
}
end

files = [["koramangala.json", "Koramangala"], ["indiranagar.json", "Indiranagar"], ["hsr.json", "HSR Layout"]]

files.each{|file|
	run_recommend(file[0], file[1])
}





