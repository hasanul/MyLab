module ProfileHelper
  @@audio_player_count = 0
  def getFansFavoriteArtists(fanid,offset=0)    
    if offset > 0
      favoriteArtistIds = User.find_by_sql ["SELECT artist_id FROM artist_fans  WHERE fan_id=? AND status=1 ORDER BY id DESC LIMIT 0,"+offset.to_s, fanid]
    else
      favoriteArtistIds = User.find_by_sql ["SELECT artist_id FROM artist_fans  WHERE fan_id=? AND status=1 ORDER BY id DESC", fanid]      
    end
    favoriteArtists = Array.new
    favoriteArtistIds.each do |fRow|        
        favArtRow = User.where("id = ? AND user_type = 'artist'",fRow.artist_id).take    
        
        if favArtRow != nil
          favoriteArtists.push(favArtRow)          
        end
        
    end #end of foreach favorite artists
    
    return favoriteArtists;
  end
  
  def getFanFriends(fan_id,artist_id=0,offset=0)
    user_details = User.find(fan_id)
    limitText = ""
    if offset > 0
      limitText = " LIMIT 0,"+offset.to_s
    end
    fanFriends = Array.new
    if artist_id > 0 && !user_details.eql?("fan")
      fanFriendIds = User.find_by_sql ["SELECT DISTINCT(fan_id) AS fan_id FROM artist_fans   WHERE fan_id !=? AND status=1 AND artist_id =? ORDER BY id DESC"+limitText, fan_id, artist_id]      
    else
      if user_details.user_type.eql?("fan")
        fanFriendIds = User.find_by_sql ["SELECT distinct(sender_id) AS fan_id FROM `friends` WHERE receiver_id=? AND status=1 union SELECT distinct(receiver_id) AS fan_id FROM `friends` WHERE sender_id=? AND status=1 ",fan_id,fan_id]
      else
        favoriteArtistsStr = getFavoriteArtistIdsStr(fan_id)
        if !favoriteArtistsStr.blank?
          fanFriendIds = User.find_by_sql ["SELECT DISTINCT(fan_id) AS fan_id FROM artist_fans   WHERE fan_id !=? AND  artist_id IN(?) ORDER BY id DESC"+limitText, fan_id, favoriteArtistsStr.split(',').map(&:to_i)]        
        else
          return fanFriends
        end        
      end
      
    end
    
    
    fanFriendIds.each do |ffRow|      
      fanFriendRow = User.where("id = ? ",ffRow.fan_id).take  
      if fanFriendRow != nil
        fanFriends.push(fanFriendRow)
      end
    end
    return fanFriends
    
  end
  
  def getArtistsFans(artistid,offset=0)
    limitText = ""
    if offset > 0
      limitText = " LIMIT 0,"+offset.to_s
    end
    
    fanIds = User.find_by_sql ["SELECT fan_id FROM artist_fans  WHERE artist_id=? AND status=1 ORDER BY id DESC"+limitText, artistid]      
    
    myFans = Array.new
    fanIds.each do |fRow|        
        fanRow = User.where("id = ? ",fRow.fan_id).take    
        
        if fanRow != nil
          myFans.push(fanRow)          
        end
        
    end #end of foreach favorite artists
    
    return myFans;
  end
  
  def getMyVideos(user_id,offset=0)    
    if offset > 0
      videoList = Video.where("user_id = ? AND published=1",user_id).order('created_at DESC').limit(offset)
    else
      videoList = Video.where("user_id = ? AND published=1",user_id).order('created_at DESC')  
    end    
    return videoList
  end
  
  def getFansFavoriteArtistsPagination(fanid,pageNo=1)
    total = ArtistFans.where("fan_id = ? AND status = 1",fanid).count()
    artistsFollowed = ArtistFans.where("fan_id = ? AND status = 1",fanid).order('created_at DESC').page(pageNo)
    favoriteArtists = Array.new
    
    artistsFollowed.each do |artistrow|      
      favArtRow = User.where("id = ? AND user_type = 'artist'",artistrow.artist_id).take
      if favArtRow != nil
        favoriteArtists.push(favArtRow)          
      end
    end    
    {:rows => favoriteArtists, :collection => artistsFollowed, :total => total}
  end
  
  def getArtistsFansPagination(artistid,pageNo=1)
    total = ArtistFans.where("artist_id = ? AND status = 1",artistid).count()
    fansFollowed = ArtistFans.where("artist_id = ? AND status = 1",artistid).order('created_at DESC').page(pageNo)
    
    fanRows = Array.new
    
    fansFollowed.each do |fRow|      
      fanRow = User.where("id = ?",fRow.fan_id).take 
      if fanRow != nil
          fanRows.push(fanRow)          
      end
    end    
    {:rows => fanRows, :collection => fansFollowed, :total => total}
  end
  
  def getFeaturedArtists()    
    featuredArtists = User.where("featured = 1 AND user_type = 'artist'").order('created_at DESC')
    return featuredArtists
  end
  
  def getMyAudios(user_id,offset=0)
    if offset > 0
      audioList = Audio.where("user_id = ? AND published=1",user_id).order('created_at DESC').limit(offset)
    else
      audioList = Audio.where("user_id = ? AND published=1",user_id).order('created_at DESC')  
    end
    
    return audioList
  end
  
  def getNewslist(user_id=0,offset=0)
    if offset > 0
      if user_id == 0
        newsList = News.where("published=1").order('created_at DESC').limit(offset)
      else
        newsList = News.where("user_id = ? AND published=1",user_id).order('created_at DESC').limit(offset)  
      end      
    else
      if user_id == 0
        newsList = News.where("published=1").order('created_at DESC')
      else
        newsList = News.where("user_id = ? AND published=1",user_id).order('created_at DESC')  
      end      
    end    
    return newsList
  end
  
  def getAdminNewslist(user_id=0,offset=0)
    if offset > 0
      newsList = AdminNews.where("published=1").order('ordering ASC').limit(offset)
    else
      newsList = AdminNews.where("published=1").order('ordering ASC')      
    end    
    return newsList
  end
  
  def getMostViewedVideos(user_id=0,offset=0)
    if offset > 0
      if user_id > 0
        videoList = Video.where("user_id=? AND published=1",user_id).order('hits DESC').limit(offset)
      else
        videoList = Video.where("published=1").order('hits DESC').limit(offset)  
      end      
    else
      if user_id > 0
        videoList = Video.where("user_id=? AND published=1",user_id).order('hits DESC')
      else
        videoList = Video.where("published=1").order('hits DESC')    
      end      
    end
    
    return videoList
  end
  
  def getCountryName(country_id)
    country_name = ""
    if country_id != nil
      countryRow = Country.where("id = ? ",country_id).take
      if countryRow != nil
        country_name = countryRow.country_name
      end
    end
    return country_name
  end
  
  def getStateName(state_id)
    state_name = ""
    if state_id != nil
      stateRow = State.where("id = ? ",state_id).take
      if stateRow != nil
        state_name = stateRow.state_name
      end
    end
    return state_name
  end
  
  def getStatesCountryName(state_id)
    country_name = ""
    if state_id != nil
      stateRow = State.where("id = ? ",state_id).take
      if stateRow != nil
        country_name = getCountryName(stateRow.country_id)
      end
    end
    return country_name
  end
  
  
  def getEventlist(user_id=0,offset=0)
    if offset > 0
      if user_id == 0
        eventList = Event.where("published=1").order('created_at DESC').limit(offset)
      else
        eventList = Event.where("user_id = ? AND published=1",user_id).order('created_at DESC').limit(offset)  
      end      
    else
      if user_id == 0
        eventList = Event.where("published=1").order('created_at DESC')
      else
        eventList = Event.where("user_id = ? AND published=1",user_id).order('created_at DESC')  
      end      
    end    
    return eventList
  end
  
  def getFavoriteArtistsNews(fanid,offset=0) 
    favoriteArtistsStr = getFavoriteArtistIdsStr(fanid)
    if favoriteArtistsStr == ""
      favoriteArtistsStr = '0'
    end
    if offset > 0
      newsList = News.where("user_id IN (?) AND published=1",favoriteArtistsStr).order('created_at DESC').limit(offset)
    else
      newsList = News.where("user_id IN (?) AND published=1",favoriteArtistsStr).order('created_at DESC')
    end    
  end
  
  def getFavoriteArtistsEvents(fanid,offset=0) 
    favoriteArtistsStr = getFavoriteArtistIdsStr(fanid)
    if favoriteArtistsStr == ""
      favoriteArtistsStr = '0'
    end
    if offset > 0
      newsList = Event.where("user_id IN (?) AND published=1",favoriteArtistsStr).order('created_at DESC').limit(offset)
    else
      newsList = Event.where("user_id IN (?) AND published=1",favoriteArtistsStr).order('created_at DESC')
    end
    return newsList
  end
  
  #my recently watched videos
  def getRecentlyWatchedVideos(user_id=0,offset=0)
    videoRows = Array.new
    if user_id > 0
      if offset > 0
        recentVideoIDsResult = VideoWatch.where("user_id = ?",user_id).select(:video_id).distinct.order('created_at DESC').limit(offset)
      else
        recentVideoIDsResult = VideoWatch.where("user_id = ?",user_id).select(:video_id).distinct.order('created_at DESC')
      end
    else
      if offset > 0
        recentVideoIDsResult = VideoWatch.select(:video_id).distinct.order('created_at DESC').limit(offset)
      else
        recentVideoIDsResult = VideoWatch.select(:video_id).distinct.order('created_at DESC')
      end
    end
    
    recentVideoIDsResult.each do |wRow|      
      videRow = Video.where("id = ? AND published=1",wRow.video_id).take 
      if videRow != nil
          videoRows.push(videRow)          
      end
    end 
    return videoRows
  end
  
  def getRecentlyWatchedVideosPagination(user_id,pageNo=1)
    total = VideoWatch.where("user_id = ?",user_id).count()
    items = VideoWatch.where("user_id = ?",user_id).order('created_at DESC').page(pageNo)
    
    videoRows = Array.new
    
    items.each do |item|      
      videRow = Video.where("id = ? AND published=1",item.video_id).take 
      if videRow != nil
          videoRows.push(videRow)          
      end
    end    
    {:rows => videoRows, :collection => items, :total => total}
  end
  
  def getFavoriteArtistsRecentlyUploadedVideos(fanid,offset=0)
    videoList = []    
    favoriteArtistsStr = self.getFavoriteArtistIdsStr(fanid);
    if favoriteArtistsStr != ""
      if offset > 0
        videoList = Video.where("user_id IN(?) AND published=1",favoriteArtistsStr.split(',').map(&:to_i)).order('created_at DESC').limit(offset)
      else
        videoList = Video.where("user_id IN(?) AND published=1",favoriteArtistsStr.split(',').map(&:to_i)).order('created_at DESC')
      end      
    end
    return videoList
  end
  
  def getFavoriteVideos(user_id,offset=0)    
    videoRows = Array.new
    favoriteVideoIDsResult = VideoFavorite.where("user_id = ?",user_id).select(:video_id).distinct.order('created_at DESC')
    favoriteVideoIDsResult.each do |wRow|      
      videRow = Video.where("id = ? AND published=1",wRow.video_id).take 
      if videRow != nil
          videoRows.push(videRow)          
      end
    end 
    return videoRows
  end
  
  def getFavoriteVideosPagination(user_id,pageNo=1)
    total = VideoFavorite.where("user_id = ?",user_id).count()
    items = VideoFavorite.where("user_id = ?",user_id).order('created_at DESC').page(pageNo)
    
    videoRows = Array.new
    
    items.each do |item|      
      videRow = Video.where("id = ? AND published=1",item.video_id).take 
      if videRow != nil
          videoRows.push(videRow)          
      end
    end    
    {:rows => videoRows, :collection => items, :total => total}
  end
  
  #get favorite artist ids str
  def getFavoriteArtistIdsStr(fanid)
    favoriteArtistIds = ArtistFans.where("fan_id = ? AND status = 1",fanid)
    favoriteArtistsStr = ""
    favoriteArtistIds.each do |fRow|                  
        if favoriteArtistsStr.blank?
          favoriteArtistsStr = fRow.artist_id.to_s
        else            
          favoriteArtistsStr = favoriteArtistsStr + "," + fRow.artist_id.to_s            
        end
               
    end #end of foreach favorite artists
    
    return favoriteArtistsStr
  end
  
  def getSlideImages
    slideList = Slide.where("slide_image!='' AND published=1").order('ordering ASC')
    return slideList
  end
  
  def isUserOnline(userInstance)
    cTime = Time.now.to_i
    timeDeff = (cTime - userInstance.lastlogintime.to_i)
    isOnline = false
    if userInstance.lastlogintime.to_i > 0 && (timeDeff <= 900)
      isOnline = true
    end
    return isOnline
  end
  
  def getUsernameByID(user_id)
    userRow = User.where("id = ?",user_id).take
    username = ''
    if userRow != nil
      username = userRow.email
    end
    return username
  end
  
  def getUserByID(user_id)
    userRow = User.where("id = ?",user_id).take    
    return userRow
  end
  
  def get_flash_audio_player(mp3_url,width=200,height=20)
    playercode = '<object type="application/x-shockwave-flash" data="/audio_players/player_mp3.swf" width="'+width.to_s+'" height="'+height.to_s+'">
              <param name="movie" value="/audio_players/player_mp3.swf" />
              <param name="bgcolor2" value="#085c68" />
              <param name="FlashVars" value="mp3='+mp3_url+'&amp;bgcolor1=696969&amp;bgcolor2=696969" />
          </object>'
    return playercode
  end
  
  def get_mediaelement_video_player(video_url,webm_url,thumb_url,width=320,height=240)
    playercode = '<center><video width="'+width.to_s+'" height="'+height.to_s+'" style="width: 100%;" id="player1" poster="'+thumb_url+'" controls="controls" preload="none">
                    <source src="'+video_url+'" type="video/mp4">
                    <source src="'+webm_url+'" type="video/webm">                    
                    <object width="'+width.to_s+'" height="'+height.to_s+'" type="application/x-shockwave-flash" data="/assets/mediaelement/flashmediaelement.swf">    
                      <param name="movie" value="/assets/mediaelement/flashmediaelement.swf" /> 
                      <param name="flashvars" value="controls=true&poster='+thumb_url+'&file='+video_url+'" />    
                      <img src="'+thumb_url+'" width="'+width.to_s+'" height="'+height.to_s+'" />
                    </object>   
                  </video></center>'
    playercode += "<script>
    $('video').mediaelementplayer({
      success: function(media, node, player) {
        $('#' + node.id + '-mode').html('mode: ' + media.pluginType);
      }
    });
    </script>"
    return playercode  
  end
  
  def get_mediaelement_audio_player(mp3_url,width=400,height=20)
    @@audio_player_count = @@audio_player_count+1
    playercode = '<audio id="audio_player'+@@audio_player_count.to_s+'" src="'+mp3_url+'" width="'+width.to_s+'"  type="audio/mp3" controls="controls"></audio>'
    playercode += "<script>
        jQuery('audio#audio_player"+@@audio_player_count.to_s+"').mediaelementplayer({
          features: ['playpause','volume'],
          pluginPath:'"+root_url+"assets/',
          flashName:'flashmediaelement.swf',
          audioWidth:'100%'
        });
    </script>"
    return playercode  
  end

  def get_flash_video_player(video_url,width=320,height=240)
    
    playercode = '<object class="playerpreview" type="application/x-shockwave-flash" data="/video_players/player_flv_maxi.swf" width="'+width.to_s+'" height="'+height.to_s+'">
                <param name="movie" value="/video_players/player_flv_maxi.swf" />
                <param name="allowFullScreen" value="true" />
                <param name="FlashVars" value="flv='+video_url+'&amp;startimage=/assets/startimage_en.jpg&amp;width='+width.to_s+'&amp;height='+height.to_s+'&amp;showstop=1&amp;showvolume=1&amp;showtime=1&amp;showfullscreen=1&amp;bgcolor1=696969&amp;bgcolor2=696969&amp;playercolor=696969&amp;showtime=2" />                
            </object>'
    return playercode  
  end  
  
  def formatDuration(duration_period,duration_unit)
    formattedDuration = duration_period
    if duration_unit == "m"
      duration_unit_text = "Month"
    elsif duration_unit == "d"
      duration_unit_text = "Day"
    elsif duration_unit == "y"
      duration_unit_text = "Year"
    end
    if duration_period > 1
      duration_unit_text = duration_unit_text + 's'
    end
    formattedDuration = formattedDuration.to_s + " "+duration_unit_text
  end
  
  def getFormattedLocation(userRow)
    formattedLocation = userRow.city.to_s
    stateName = getStateName(userRow.state_id)
    countryName = getCountryName(userRow.country_id)
    if stateName!=""
      if formattedLocation!=''
        formattedLocation +=  ", "+stateName
      else
        formattedLocation = stateName
      end
    end
    if userRow.zip.to_s!=""
      if formattedLocation!=''
        formattedLocation +=  ", "+userRow.zip
      else
        formattedLocation = userRow.zip
      end
    end
    if countryName!=""
      if formattedLocation!=''
        formattedLocation +=  ", "+countryName
      else
        formattedLocation = countryName
      end
    end
    if formattedLocation == ""
      formattedLocation = "N/A"
    end
    return formattedLocation
  end
  
  #in terms of miles
  def GetNearestPerformers(userInstance,distance,limit=0)
    nearestArtists = []
    if userInstance.latitude != nil && userInstance.longitude != nil
      lat = userInstance.latitude.to_s
      lon = userInstance.longitude.to_s
      
      favoriteArtistsStr = getFavoriteArtistIdsStr(userInstance.id)
      if favoriteArtistsStr.blank?
        favoriteArtistsStr = '0'
      end
      
      limitText = ''
      if limit > 0
        limitText = " LIMIT 0,"+limit.to_s
      end
      distance_col = "( 3959 * acos( cos( radians("+lat+") ) * cos( radians( latitude ) ) * cos( radians( longitude ) - radians("+lon+") ) + sin( radians("+lat+") ) * sin( radians( latitude ) ) ) )"
      nearestEvents = Event.find_by_sql ["SELECT user_id,"+distance_col+" AS distance FROM events
                                    WHERE events.user_id IN(?) AND (latitude IS NOT NULL AND longitude IS NOT NULL) AND "+distance_col+"<=? AND published=1 ORDER BY distance ASC"+limitText,favoriteArtistsStr.split(',').map(&:to_i),distance]
      artistIds = Array.new
      nearestEvents.each do |eRow|
          if !artistIds.include?(eRow.user_id)
            artistIds.push(eRow.user_id)
            artistRow = User.where("id = ? AND user_type = 'artist'",eRow.user_id).take
            if artistRow != nil
              nearestArtists.push(artistRow)          
            end
          end
      end #end of foreach favorite artists
    end
    
    return nearestArtists
  end
  
  def GetArtistsNearestPerformers(userInstance,distance,limit=0)
    nearestArtists = []
    if userInstance.latitude != nil && userInstance.longitude != nil
      lat = userInstance.latitude.to_s
      lon = userInstance.longitude.to_s
      
      limitText = ''
      if limit > 0
        limitText = " LIMIT 0,"+limit.to_s
      end
      distance_col = "( 3959 * acos( cos( radians("+lat+") ) * cos( radians( latitude ) ) * cos( radians( longitude ) - radians("+lon+") ) + sin( radians("+lat+") ) * sin( radians( latitude ) ) ) )"
      nearestEvents = Event.find_by_sql ["SELECT user_id,"+distance_col+" AS distance FROM events
                                    WHERE (latitude IS NOT NULL AND longitude IS NOT NULL) AND "+distance_col+"<=? AND published=1 AND events.user_id!=? ORDER BY distance ASC"+limitText,distance,userInstance.id]
      artistIds = Array.new
      nearestEvents.each do |eRow|
          if !artistIds.include?(eRow.user_id)
            artistIds.push(eRow.user_id)
            artistRow = User.where("id = ? AND user_type = 'artist'",eRow.user_id).take
            if artistRow != nil
              nearestArtists.push(artistRow)          
            end
          end
      end #end of foreach favorite artists
    end
    
    return nearestArtists
  end
  
  def getHomepageVideos(cat_limit=5,item_limit=5)
    catWithVideos = Array.new
    categories = MusicCategory.where("show_at_home_page = 1").order('ordering ASC').limit(cat_limit)
    #{:rows => favoriteArtists, :collection => artistsFollowed, :total => total}
    categories.each do |catRow|
      cat_videos = Video.where("published=1 AND featured = 1")
      cat_videos = cat_videos.joins('INNER JOIN music_categories_videos ON music_categories_videos.video_id = videos.id')
      cat_videos = cat_videos.where("music_categories_videos.music_category_id=?",catRow.id).order('videos.created_at DESC').limit(item_limit)
      if cat_videos.length > 0
        cat_vars = {
              "category" => catRow,
              "videos" => cat_videos
        }
        catWithVideos.push(cat_vars)  
      end      
    end 
    return catWithVideos
  end
  
  def getFanStats(artist_id)
    fanStats = User.joins('INNER JOIN artist_fans AS af ON af.fan_id = users.id').where("af.artist_id=?",artist_id).select("city,COUNT(*) AS fan_count").group("city").order('fan_count DESC')
    return fanStats
  end
  
  def getFanTotal(artist_id)
    total = ArtistFans.where("artist_id=?",artist_id).count()
    return total
  end
  
  def getMusicTitleByID(id)
    musicRow = Audio.where("id = ?",id).take
    musicTitle = ''
    if musicRow != nil
      musicTitle = musicRow.title
    end
    return musicTitle
  end
  
  def getMusicsArtistName(music_id,return_link=false)
    musicRow = Audio.where("id = ?",music_id).take
    artistName = ''
    if musicRow != nil
      artistInfo = self.getUserByID(musicRow.user_id)
      if artistInfo!=nil
        
        artistName = artistInfo.first_name+" "+artistInfo.last_name
        
        if return_link
          artistName = link_to getMusicsArtistName(music_id).html_safe, artist_dashboard_path(id: artistInfo.id.to_s+':'+artistName.parameterize)
        end        
      end
    end
    return artistName
  end
  
  def getPlanById(plan_id)
    return Plan.where("id = ?",plan_id).take
  end
  
  def getMusicSoldCount(music_id)
    return OrderItem.where("product_id = ? AND order_status = 1",music_id).count()
  end
  
  def youtube_embed(youtube_url,width,height)
    if youtube_url[/youtu\.be\/([^\?]*)/]
      youtube_id = $1
    else
      # Regex from # http://stackoverflow.com/questions/3452546/javascript-regex-how-to-get-youtube-video-id-from-url/4811367#4811367
      youtube_url[/^.*((v\/)|(embed\/)|(watch\?))\??v?=?([^\&\?]*).*/]
      youtube_id = $5
    end  
    %Q{<iframe title="YouTube video player" width="#{ width }" height="#{ height }" src="http://www.youtube.com/embed/#{ youtube_id }" frameborder="0" allowfullscreen></iframe>}
  end
  
  def youtube_embed_thumb(youtube_url,thumbtype="default")
    if youtube_url[/youtu\.be\/([^\?]*)/]
      youtube_id = $1
    else
      # Regex from # http://stackoverflow.com/questions/3452546/javascript-regex-how-to-get-youtube-video-id-from-url/4811367#4811367
      youtube_url[/^.*((v\/)|(embed\/)|(watch\?))\??v?=?([^\&\?]*).*/]
      youtube_id = $5
    end
    if thumbtype == "default" #120X90
      %Q{http://i1.ytimg.com/vi/#{ youtube_id }/default.jpg}
    elsif thumbtype == "mqdefault" #320X180
      %Q{http://i1.ytimg.com/vi/#{ youtube_id }/mqdefault.jpg}
    elsif thumbtype == "hqdefault" #480X360
      %Q{http://i1.ytimg.com/vi/#{ youtube_id }/hqdefault.jpg}
    end

  end
  
  #return image source
  def getUserAvatar(userInstance,avatartype="small")
    
    # if user is authenticated by facebook or twitter, remote profile avatar will be shown
    if userInstance.avatar_url!=nil
      user_identity = Authentication.find_by user_id: userInstance.id
    
      if user_identity
        if avatartype.eql?("small")
          
          if user_identity.provider == 'facebook'
            targetFile = userInstance.avatar_url + '?width=58&height=58'
          elsif user_identity.provider == 'twitter'
            targetFile = userInstance.avatar_url
          elsif user_identity.provider == 'google_oauth2'
            targetFile = userInstance.avatar_url
          end
          
        elsif avatartype.eql?("large")
          
          if user_identity.provider == 'facebook'
            targetFile = userInstance.avatar_url + '?width=212&height=212'
          elsif user_identity.provider == 'twitter'
            targetFile = userInstance.avatar_url
          elsif user_identity.provider == 'google_oauth2'
            targetFile = userInstance.avatar_url
          end
        end
        return targetFile
      end
    end
    
    if avatartype.eql?("small")
      targetFile = "/uploads/#{userInstance.class.to_s.underscore}/profile_photo/#{userInstance.id}/small_#{userInstance.profile_photo}"
      
      if !File.exist?("#{Rails.root}/public/#{targetFile}")
        targetFile = "/uploads/#{userInstance.class.to_s.underscore}/profile_photo/small_no-avatar.png" 
      end
    elsif avatartype.eql?("large")
      targetFile = "/uploads/#{userInstance.class.to_s.underscore}/profile_photo/#{userInstance.id}/large_#{userInstance.profile_photo}"
      if !File.exist?("#{Rails.root}/public/#{targetFile}")
        targetFile = "/uploads/#{userInstance.class.to_s.underscore}/profile_photo/large_no-avatar.png" 
      end
    elsif avatartype.eql?("main")
      targetFile = "/uploads/#{userInstance.class.to_s.underscore}/profile_photo/#{userInstance.id}/#{userInstance.profile_photo}"
      if !File.exist?("#{Rails.root}/public/#{targetFile}")
        targetFile = "/uploads/#{userInstance.class.to_s.underscore}/profile_photo/large_no-avatar.png" 
      end
    end
    return targetFile
  end
  
  def getVideoThumb(videoInstance,youtubeImageSize="default",width=138,height=77,video_link_type="watch")
    video_link = ""
    if video_link_type.eql?("watch")
      video_link = watch_video_path(:id => videoInstance.id.to_s+':'+videoInstance.title.parameterize)
    elsif video_link_type.eql?("user")
      video_link = user_video_path(:user_id=>current_user.id,:id => videoInstance.id.to_s+':'+videoInstance.title.parameterize)
    end
    if videoInstance.source.to_s == "remote" && (!videoInstance.remote_path.index('www.youtube.com').nil? || !videoInstance.remote_path.index('youtu.be').nil?)
      video_img = image_tag youtube_embed_thumb(videoInstance.remote_path,youtubeImageSize),:class => "video_thumb", :width => width, :height => height
      if !video_img.nil?
        link_to video_img, video_link if videoInstance.remote_path
      end      
    elsif videoInstance.path_url(:thumb)
      if youtubeImageSize.eql?("hqdefault")
        video_img = image_tag videoInstance.path_url(:large),:class => "img-responsive video_thumb", :width => width, :height => height if videoInstance.path?
      elsif youtubeImageSize.eql?("mqdefault")
        video_img = image_tag videoInstance.path_url(:thumb),:class => "video_thumb", :width => width, :height => height if videoInstance.path?
      else
        video_img = image_tag videoInstance.path_url(:small),:class => "img-responsive video_thumb", :width => width, :height => height if videoInstance.path?
      end
      if !video_img.nil?
        link_to video_img, video_link if videoInstance.path
      end      
    end
  end
  
  def getUsersVideoCount(user_id)
    return Video.where("published=1 AND user_id=?",user_id).count()
  end
  
  def getFriendRequestRow(user_id1,user_id2)
    Friend.where("(sender_id=? AND receiver_id=?) OR (sender_id=? AND receiver_id=?)",user_id1,user_id2,user_id2,user_id1).take
  end
  
  def getFriendCount(user_id)
    return Friend.where("(sender_id=? OR receiver_id=?) AND status=1",user_id,user_id).count()
  end
  def getPendingFriendRequestCount(user_id)
    return Friend.where("receiver_id=? AND status=0",user_id).count()
  end
  def getAwaitingFriendRequestCount(user_id)
    return Friend.where("sender_id=? AND status=0",user_id).count()
  end
  
end
