# Comment this out when done final seed:
# return if Rails.env.production?

require 'rspotify'
require 'open-uri'
require 'json'
require 'nokogiri'
require 'rest-client'

p "Destroying users..."
User.destroy_all
p "Destroying creators..."
Creator.destroy_all
p "Destroying followed creators..."
FollowedCreator.destroy_all
p "Destroying books..."
Book.destroy_all

# # =================================User Start=============================================

p "Creating some users..."
emails = %w[egehdrgl@gmail.com ege@minder.quest casey@minder.quest hugo@minder.quest adou@minder.quest garrett@minder.quest]
password = "123456"
emails.each do |email|
  User.create(email: email, password: password)
end

# # ================================= Creators Start ==========================================
p "Creating creators..."
artists = []
# ["Gorillaz", "Lou Reed", "Taylor Swift", "The 1975", "Yeah Yeah Yeahs", "Megadeth", "Horace Andy",
#   "Arctic Monkeys", "ODESZA", "The Killers", "Cigarettes After Sex", "Flaming Lips",
#   "Backstreet Boys",
#   "DJ Khaled", "Ozzy Osbourne",
#   "Ringo Starr", "Bjork",
#   "Twenty One Pilots",
#   "Ibrahim Maalouf",  "RY X",
#   "Novo Amor", "The Smashing Pumpkins", "Stromae"]

directors = ["Ryan Coogler", "George Miller", "Steven Spielberg", "James Cameron", "Jon Watts", "Gina Prince-Bythewood", "Zach Cregger",  "Castille Landon",
    "David Gordon Green", "Ol Parker", "Bong Joon-ho", "Nicholas Stoller", "Mark Mylod", "Jordan Peele", "Jaume Collet-Serra"]

authors = ["Malcolm Gladwell", "Zadie Smith", "Christine Sinclair"]
#  "Stephen King", "Ryan Holiday",
#   "Jamie Oliver", "Michelle Obama", "Jonathan Cahn", "Rupi Kaur", "Randall Munroe",
#   "Kate Reid", "Gabor Mate", "Imani Perry", "Chuck Klosterman", "Margaret Atwood", "Philip Rosenthal"]

p "Creating authors..."
authors.each do |author|
  creator = Creator.new
  creator.content_type = "Book"
  author.gsub!(" ", "_")
  url = "https://en.wikipedia.org/wiki/#{author}"
  html_file = URI.open(url).read
  html_doc = Nokogiri::HTML(html_file)
  image = ""
  html_doc.search(".infobox-image img").each do |element|
    image = element.attributes["src"].value
  end
  creator.poster_url = image
  author.gsub!("_", " ")
  creator.name = author
  creator.save!
end

p "Creating music creators..."
artists.each do |artist|
  art = RSpotify::Artist.search(artist).first
  poster = art.images[0]["url"]
  p artist
  creator = Creator.new
  creator.content_type = "Music"
  creator.name = artist
  creator.poster_url = poster
  creator.save!
  path = ""
end

p "Creating movie creators..."
directors.each do |director|
  creator = Creator.new
  creator.name = director
  creator.content_type = "Movie"
  tmdb_api_upcoming_call = "https://api.tmdb.org/3/search/person?api_key=#{ENV["TMDB_API_KEY"]}&query=#{director}"
  begin
    response = URI.open(tmdb_api_upcoming_call).read
    results = JSON.parse(response)
    actor_id = results["results"][0]["id"]

    tmdb_api_actor_photo = "https://api.themoviedb.org/3/person/#{actor_id}/images?api_key=#{ENV["TMDB_API_KEY"]}"
    response = URI.open(tmdb_api_actor_photo).read
    results = JSON.parse(response)
    path = "https://image.tmdb.org/t/p/w220_and_h330_face/#{results["profiles"][0]["file_path"]}"
  rescue
    path = ""
  end
  creator.poster_url = path
  creator.save!
end

p "Assigning creators to user's followed creators..."
Creator.all.each do |creator|
  followed_creator = FollowedCreator.new
  followed_creator.user = User.all.first
  followed_creator.creator = creator
  followed_creator.save
end
# # ================================= Books Start ==========================================

p "Creating books"
authors.each do |author|
  search = URI.open("https://www.googleapis.com/books/v1/volumes?q=inauthor:#{author}&orderBy=newest&num=1&langRestrict=en&key=#{ENV["GOOGLE_KEY"]}").read
  response = JSON.parse(search)
  isbn = response["items"][0]["volumeInfo"]["industryIdentifiers"][0]["identifier"]
  poster = ""
  begin
    results = RestClient.get("https://api2.isbndb.com/book/#{isbn}", headers={"Authorization" => "50005_da8beb2efdd07d6955f154720bb66bcd"})
    poster = JSON.parse(results)["book"]["image"]
  rescue
    poster = "https://images.unsplash.com/photo-1541963463532-d68292c34b19?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1376&q=80"
  end
  Book.create!(
    name: response["items"][0]["volumeInfo"]["title"],
    release_date: response["items"][0]["volumeInfo"]["publishedDate"],
    description: response["items"][0]["volumeInfo"]["description"],
    poster_url:   poster,
    creator_id: Creator.where(name: author).first.id
  )
end

# authors.each do |author|
#   search = URI.open("https://www.googleapis.com/books/v1/volumes?q=inauthor:#{author}&orderBy=newest&num=1&langRestrict=en&key=#{ENV["GOOGLE_KEY"]}").read
#   response = JSON.parse(search)
#   isbn = response["items"][0]["volumeInfo"]["industryIdentifiers"][0]["identifier"]
#   begin
#     results = RestClient.get("https://api2.isbndb.com/book/#{isbn}", headers={"Authorization" => "50005_da8beb2efdd07d6955f154720bb66bcd"})
#     author
#     JSON.parse(results)["book"]["image"]
#   rescue
#     p "Could not find #{author}"
#   end
# end

# =======================Getting upcoming albums for creators===============================
p "Finding upcoming albums for creators..."

for page in 1..11
  i = 1
  doc = Nokogiri::HTML(URI.open("https://www.albumoftheyear.org/upcoming/#{page}/"))
  doc.search('.albumBlock').each do |link|
    img = link.search('img').attr('data-srcset').value unless link.search('img').attr('data-srcset').nil?
    img = img.split[0] unless img.nil?
    date = link.search('.date').text.strip
    date = Date.parse(date).strftime("%F") unless date.length.zero?
    artist_title = link.search('.artistTitle').text.strip
    album_title = link.search('.albumTitle').text.strip

    unless date.nil? && artist_title.nil?
      if Creator.where(name: artist_title)
        album = Album.new
        album.poster_url = img.nil? ? "" : img
        album.release_date = date
        album.name = album_title
        album.creator = Creator.where(name: artist_title).first
        album.save
      end
    end
    break if i == 60

    i += 1
  end
end

# # =======================Getting upcoming concerts for creators===============================
p "Finding concerts for creators..."
Creator.all.each do |artist|
  artist
  buffer = URI.open("https://app.ticketmaster.com/discovery/v2/events.json?size=10&apikey=#{ENV["TICKETMASTER_API_KEY"]}&city=Montreal&keyword=#{artist.name}").read

  response = JSON.parse(buffer)["_embedded"]
  unless response.nil?
    event = response["events"].first
    event_name = event["name"]
    event_image = event["images"].first["url"]
    event_date = event["dates"]["start"]["localDate"]
    event_url = event["url"]
    event_venue = event["_embedded"]["venues"].first["name"]
    event_address = event["_embedded"]["venues"].first["address"]["line1"]
  end
  unless event.nil?
    concert = Concert.new
    concert.name = event_name
    concert.date = event_date
    concert.venue = event_venue
    concert.address = event_address
    concert.poster_url = event_image
    concert.event_url = event_url
    concert.creator = artist
    concert.save
  end
  sleep(0.5)
end

today = Date.today
today = today.strftime("%F")
six_months = Date.today + 180
six_months = six_months.strftime("%F")

# # # =======================Getting upcoming movies for creators===============================

p "Finding upcoming movies from creators..."
for i in 1..10
  tmdb_api_upcoming_call = "https://api.themoviedb.org/3/discover/movie?api_key=#{ENV["TMDB_API_KEY"]}&language=en-US&primary_release_date.gte=#{today}&primary_release_date.lte=#{six_months}&page=#{i}"
  response = URI.open(tmdb_api_upcoming_call).read
  results = JSON.parse(response)
  movies = results["results"]
  movies.each do |movie|
    movie_id = movie["id"]
    tmdb_api_credits_call = "https://api.themoviedb.org/3/movie/#{movie_id}/credits?api_key=#{ENV["TMDB_API_KEY"]}&language=en-US"
    credits_response = URI.open(tmdb_api_credits_call).read
    credits_results = JSON.parse(credits_response)
    movie_cast = credits_results["crew"]
    movie_cast.each do |crew|
      director = crew["name"] if crew["job"] == "Director"
      if Creator.where(name: director)
        mov = Movie.new
        mov.name = movie["original_title"]
        mov.release_date = movie["release_date"]
        mov.description = movie["overview"]
        mov.poster_url = "https://image.tmdb.org/t/p/w500#{movie['poster_path']}"
        mov.creator = Creator.where(name: director).first
        mov.save
      end
    end
  end
end
