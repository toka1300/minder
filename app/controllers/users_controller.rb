class UsersController < ApplicationController
  def spotify
    spotify_user = RSpotify::User.new(request.env['omniauth.auth'])
    artists = spotify_user.following(type: "artist", limit: 20)
    artists.each do |artist|
      name = artist.name
      photo = artist.images.second["url"]
      creator = Creator.new
      followed = FollowedCreator.new
      creator.name = name
      creator.poster_url = photo
      creator.save
      unless creator.id.nil?
        followed.user = current_user
        followed.creator = creator
        followed.save
      end
    end
    redirect_to my_creators_path
  end

  def my_favorites
    user = current_user
    @favorites = user.all_favorited
    user_favorites = current_user.all_favorited
    if params[:query].present?
      case params[:query]
      when "Music"
        @favorites = []
        user_favorites.each do |followed|
          @favorites.push(followed) if followed.instance_of?(Album) || followed.instance_of?(Concert)
        end
      when "Movie"
        @favorites = []
        user_favorites.each do |followed|
          @favorites.push(followed) if followed.instance_of?(Movie.new.class)
        end
      when "Book"
        @favorites = []
        user_favorites.each do |followed|
          @favorites.push(followed) if followed.instance_of?(Book.new.class)
        end
      end
    else
      @favorites = current_user.all_favorited
    end
  end

  def unfavorite
    favorited = current_user.all_favorited
    to_unfav = 0
    favorited.each do |fav|
      to_unfav = fav if fav.id == params[:id].to_i
    end
    current_user.unfavorite(to_unfav)
    redirect_to user_favorites_path
  end

  def custom_unfav
    favorited = current_user.all_favorited
    to_unfav = 0
    favorited.each do |fav|
      to_unfav = fav if fav.id == params[:id].to_i
    end
    current_user.unfavorite(to_unfav)
  end
end
