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

# =================================User Start=============================================

p "Creating some users..."
emails = %w[egehdrgl@gmail.com ege@minder.quest casey@minder.quest hugo@minder.quest adou@minder.quest]
password = "123456"
emails.each do |email|
  User.create(email: email, password: password)
end

# ================================= Creators Start ==========================================
p "Creating creators..."
artists = ["Muse", "Lou Reed", "DJ Khaled", "Ezra Furman", "Pantha Du Prince", "Embrace", "Death Scythe", "Megadeth", "Ozzy Osbourne",
  "Beacon", "Inglorious", "Ringo Starr", "Clutch", "Codeine", "Nikki Lane", "Bjork", "Slipknot",
  "Kolb", "Young the Giant", "The Snuts", "Bill Callahan", "Loyle Carner", "Kailee Morgue",
  "Twenty One Pilots", "Elsiane", "Zimmer", "ODESZA", "My Chemical Romance", "Backstreet Boys",
  "Shame", "The White Buffalo", "Knocked Loose", "Jonas", "Aitch", "Regal",
  "Porcupine Tree", "Lynda Lemay", "Stick To Your Guns", "Zucchero", "Jungle",
  "Ibrahim Maalouf", "The Killers", "RY X", "Matt Lang", "Spencer Brown",
  "Trentemoller", "Novo Amor", "Cigarettes After Sex", "Julien Clerc", "Gorillaz",
  "Demi Lovato", "The Smashing Pumpkins", "Tommy Cash", "Peach Tree Rascals", "Tchami",
  "Skullcrusher", "Alan Walker", "The Smile", "Stromae"]

directors = ["Jon Watts", "Gina Prince-Bythewood", "Zach Cregger", "George Miller", "Castille Landon",
    "Paul Fisher", "David Gordon Green", "Parker Finn", "Ol Parker", "Adamma Ebo", "Nicholas Stoller", "Carlota Pereda",
    "Guillaume Lambert", "Nick Hamm", "James Cameron", "Mark Mylod", "Ryan Coogler", "Robert Zappia", "Jaume Collet-Serra"]

authors = ["Malcolm Gladwell", "Stephen King", "Ryan Holiday", "J.K. Rowling", "Robert Galbraith", "Jamie Oliver",
  "Jonathan Cahn", "Rupi Kaur", "Matthew Perry", "Randall Munroe", "Kate Reid", "Gabor Mate", "Michelle Obama",
  "Christine Sinclair", "Bob Dylan", "Jerry Seinfeld"]

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
  creator = Creator.new
  creator.name = artist
  creator.content_type = "Music"
  artist.gsub!(" ", "_")
  url = "https://en.wikipedia.org/wiki/#{artist}"
  html_file = URI.open(url).read
  html_doc = Nokogiri::HTML(html_file)
  image = ""
  html_doc.search(".infobox-image img").each do |element|
    image = element.attributes["src"].value
  end
  creator.poster_url = image
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
# ================================= Books Start ==========================================

p "Creating books"
authors.each do |author|
  search = URI.open("https://www.googleapis.com/books/v1/volumes?q=inauthor:#{author}&orderBy=newest&num=1&langRestrict=en&key=#{ENV["GOOGLE_KEY"]}").read
  response = JSON.parse(search)
  Book.create!(
    name: response["items"][0]["volumeInfo"]["title"],
    release_date: response["items"][0]["volumeInfo"]["publishedDate"],
    description: response["items"][0]["volumeInfo"]["description"],
    poster_url:   response["items"][0]["volumeInfo"]["imageLinks"]["thumbnail"],
    creator_id: Creator.where(name: author).first.id
  )
end

# authors.each do |author|
#   author.gsub!(" ", "%20")
#   p author
#   results = RestClient.get("https://api2.isbndb.com/author/#{author}?page=10&pageSize=30", headers={
#   "Authorization" => "48314_72662961febf77ecb4b86a768b7ca6dc"
#   })
#   author.gsub!("%20", " ")
#   JSON.parse(results)["books"].each do |book|
# #     #  -------------Converting all formats to date format------------------------
# #     # begin
# #       # publishing_date = Date.parse(book["date_published"])
# #       # This just works for
# #     # rescue
# #       # Use Regex to get the year from: book["date_published"] and store in publishing_date
# #       # Date.new and just set it to jan. 1 of that year
# #     # end

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

# =======================Getting upcoming concerts for creators===============================
p "Finding concerts for creators..."
Creator.all.each do |artist|
  buffer = URI.open("https://app.ticketmaster.com/discovery/v2/events.json?size=10&apikey=#{ENV["TICKETMASTER_KEY"]}&city=Montreal&keyword=#{artist.name}").read
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



# # =======================Getting upcoming movies for creators===============================
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

album = Album.first
creator = album.creator
concert = Concert.new(name: "Kim Concert", date: "2022-09-22", venue: "Centre Bell", address: "Centre Bell")
concert.creator = creator
concert.save
