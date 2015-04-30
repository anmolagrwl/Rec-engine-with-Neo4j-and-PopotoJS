require 'rubygems'
require 'open-uri'
require 'sentimental'
require 'json'
require 'neo4j-core'

class GooglePlaces
  KEY = 'AIzaSyAlhwar36zhTpcOZkkA4_t9wEWU95reGPY'
  PLACEURL = 'https://maps.googleapis.com/maps/api/place'
  GEOCODEURL = 'https://maps.googleapis.com/maps/api/geocode'

  attr_accessor :session, :analyzer

  def initialize
    @session = Neo4j::Session.open(:server_db)
    Sentimental.load_defaults
    @analyzer = Sentimental.new
  end

  def load_data
    files = [
      { name: "Indiranagar", file: 'indiranagar', coords: { lat: 12.9718915, lng: 77.6411545 } },
      { name: "HSR Layout", file: 'hsr', coords: { lat: 12.9081357, lng: 77.64760799999999 } },
      { name: "koramangala", file: 'koramangala', coords: { lat: 12.9279232, lng: 77.62710779999999 } }
    ]
    # files.each { |file| commit_neo4j(file) } - Uncomment to push this to Neo4J
    files.each_with_index { |file, ix| files[ix] = commit_json(file) }
    File.open("data/locations.json", 'w') {|f| f.write(files.to_json) }
  end

  def commit_neo4j(file)
    area = Neo4j::Node.create({name: file[:name], food_sentiment: 0, education_sentiment: 0, healthcare_sentiment: 0}, :area)
    data = fetch_ammenities(file[:coords][:lat], file[:coords][:lng])
    scores = { }
    data.keys.each do |key|
      scores[key] = []
      data[key].each do |entity| 
        scores[key] << commit_entity(entity, key, area)
      end
    end
    scores.keys.each { |key| area["#{key.to_s}_sentiment".to_sym] = calculate_average(scores[key]) }
  end

  def commit_json(file)
    scores = { }
    data = fetch_ammenities(file[:coords][:lat], file[:coords][:lng])
    data.keys.each do |key|
      scores[key] = []
      data[key].each do |entity| 
        score = entity['rating'] || 0
        (entity["comments"] || []).each{ |comment| scores[key] << calculate_score(score, comment[:sentiment]) }
      end
    end
    scores.keys.each { |key| file["#{key}_average_sentiment"] = calculate_average(scores[key]) }
    File.open("data/#{file[:file]}.json", 'w') {|f| f.write(data.to_json) }
    file
  end

  def commit_entity(entity, type, parent)
    score = entity['rating'] || 0
    location_type = "has_#{type.to_s}_option".to_sym
    comment_type = "has_#{type.to_s}_option_comment".to_sym
    node = Neo4j::Node.create({
      name: entity["name"], 
      latitude: entity["geometry"]["location"]["lat"], 
      longitude: entity["geometry"]["location"]["lng"], 
      address: entity["address"], 
      rating: entity["rating"],
      icon: entity['icon'],
      place_id: entity['place_id'],
      website: entity['website'],
      phone_no: entity['phone_no']
    }, type)
    parent.create_rel(location_type, node)
    (entity["comments"] || []).each do |comment|
      comment_node = Neo4j::Node.create({comment: comment[:text], sentiment: comment[:sentiment]}, :comment)
      parent.create_rel(comment_type, comment_node)
      score = calculate_score(score, sentiment)
    end
    score
  end

  def calculate_score(score, sentiment)
    score = sentiment == :positive ? score + 1 : score - 1
    score = 5 if score > 5
    score = 0 if score < 0
    score
  end

  def calculate_average(scores)
    avg_score = 0
    scores.each { |score| avg_score += score }
    avg_score = avg_score == 0 ? 0 : avg_score / scores.size
  end

  def parse_json(url_part, type)
    url = type.eql?('place') ? GooglePlaces::PLACEURL : GooglePlaces::GEOCODEURL
    uri = URI.parse(URI.encode("#{url}/#{url_part}"))
    uri.query += uri.query.empty? ? "key=#{key}" : "&key=#{GooglePlaces::KEY}"
    JSON.parse(open(uri.to_s).read)
  end

  def fetch_ammenities(lat, long)
    parsers = {
        food: %w(food bakery grocery_or_supermarket meal_delivery meal_takeaway restaurant),
        healthcare:  %w(dentist doctor health hospital pharmacy physiotherapist),
        education:  %w(school university),
    }
    data = parse_json("nearbysearch/json?location=#{lat},#{long}&radius=1000&types=food|park|" +
                      "bakery|cafe|clothing_store|dentist|doctor|department_store|grocery_or_supermarket|health|" +
                      "hospital|meal_delivery|meal_takeaway|pharmacy|physiotherapist|restaurant|school|shopping_" +
                      "mall|store|university", 'place')
    data = data['results'].map { |row| row.select { |key, value| %w(geometry icon id name types place_id).include?(key.to_s) } }
    data.each_with_index do |rec, ix|
      details = parse_json("details/json?placeid=#{rec['place_id']}", 'place')
      data[ix] = data[ix].merge({
                                    'address' => details['result']['formatted_address'],
                                    'rating' => details['result']['rating'],
                                    'website' => details['result']['website'],
                                    'comments' => [],
                                    'phone_no' => details['international_phone_number'],
                                })

      (details['result']['reviews'] || []).map { |rw| rw['text'] }.each do |comment|
        data[ix]['comments'] << { text: comment, sentiment: @analyzer.get_sentiment(comment) }
      end
    end

    output = {
        food: data.select { |row| (row['types'] - parsers[:food]).size < row['types'].size },
        healthcare: data.select { |row| (row['types'] - parsers[:healthcare]).size < row['types'].size },
        education: data.select { |row| (row['types'] - parsers[:education]).size < row['types'].size },
    }
    output
  end
end

gp = GooglePlaces.new
gp.load_data