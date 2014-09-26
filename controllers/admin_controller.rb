class AdminController < ApplicationController
  
  before_filter :authenticate_user!
  before_filter :is_admin
  protect_from_forgery :except => [:save_settings,:save_user,:save_video]
  
  def dashboard
  end
  
  def users
    @search = params[:search].to_s
    @total = User.where('role = "administrator"').
                      where('first_name LIKE ? OR last_name LIKE ? OR phone LIKE ? OR email LIKE ?', "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%").count()
    
    @items = User.where('role = "administrator"')
            .where('first_name LIKE ? OR last_name LIKE ? OR phone LIKE ? OR email LIKE ?', "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%")
            .order('first_name ASC').paginate(:page => params[:page], :per_page => 10) 
  end
  
  def artists
    @search = params[:search].to_s
    
    if params[:sort_by].present?
      @sort_by = params[:sort_by].to_s
    else
      @sort_by = 'first_name'
    end
    
    if params[:sort_dir].present?
      @sort_dir = params[:sort_dir].to_s
    else
      @sort_dir = 'asc'
    end
    
    @total = User.where('user_type = "artist"').
              where('first_name LIKE ? OR last_name LIKE ? OR phone LIKE ? OR email LIKE ?', "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%").count()
    
    @all_items = User.where('user_type = "artist"')
            .where('first_name LIKE ? OR last_name LIKE ? OR phone LIKE ? OR email LIKE ?', "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%")
            .order(@sort_by + ' ' + @sort_dir.upcase)
    
    @items = @all_items.paginate(:page => params[:page], :per_page => 10)
    
    respond_to do |format|
      format.html
      format.csv
    end
    
  end
  
  def users_json
    @sEcho = params[:sEcho]
    
    @total_artist = User.where('user_type = ?', params[:user_type]).
                      where('first_name LIKE ? OR last_name LIKE ? OR phone LIKE ? OR email LIKE ?', "%#{params[:sSearch]}%", "%#{params[:sSearch]}%", "%#{params[:sSearch]}%", "%#{params[:sSearch]}%").all
    
    @rows = User.where('user_type = ?', params[:user_type])
            .where('first_name LIKE ? OR last_name LIKE ? OR phone LIKE ? OR email LIKE ?', "%#{params[:sSearch]}%", "%#{params[:sSearch]}%", "%#{params[:sSearch]}%", "%#{params[:sSearch]}%")
            .find(:all, :limit => params[:iDisplayLength], :offset => params[:iDisplayStart], :order=> 'first_name ASC')
    
    artist_rows = Array.new
    @rows.each_with_index do |row, index|
      
      artist_row = Array.new
      artist_row.push(row.first_name)
      artist_row.push(row.last_name)
      artist_row.push(row.email)
      artist_row.push(row.phone)
      artist_row.push('<a href=""')
      
      artist_rows.push(artist_row)         
    end
    
    render :json => { :sEcho => @sEcho,
                      :iTotalRecords => @total_artist.count,
                      :iTotalDisplayRecords => @total_artist.count,
                      :aoColumns => [
                                      {:sName=>"first_name",:sTitle=>"First Name",:bSortable=>true,:bVisible=>true},
                                      {:sName=>"last_name",:sTitle=>"Last Name",:bSortable=>true,:bVisible=>true},
                                      {:sName=>"email",:sTitle=>"Email",:bSortable=>true,:bVisible=>true},
                                      {:sName=>"phone",:sTitle=>"Phone",:bSortable=>true,:bVisible=>true},
                                      {:sName=>"actions",:sTitle=>"Actions",:bSortable=>false,:bVisible=>true}
                                    ],
                      :aaData => artist_rows
                    }
  end
  
  def fans
    @search = params[:search].to_s
    @total = User.where('user_type = "fan"').
                      where('first_name LIKE ? OR last_name LIKE ? OR phone LIKE ? OR email LIKE ?', "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%").count()
    
    @items = User.where('user_type = "fan"')
            .where('first_name LIKE ? OR last_name LIKE ? OR phone LIKE ? OR email LIKE ?', "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%")
            .order('first_name ASC').paginate(:page => params[:page], :per_page => 10) 
  end
  
  def slides
    @search = params[:search].to_s
    if @search.length > 0
      searchText = '%'+@search+'%'
      @slides = Slide.where("title LIKE ? OR `desc` LIKE ?",searchText,searchText).order('ordering ASC').paginate(:page => params[:page], :per_page => 10)
    else
      @slides = Slide.order('ordering ASC').paginate(:page => params[:page], :per_page => 10)    
    end    
  end
  
  def music
    @search = params[:search].to_s
    if @search.length > 0
      searchText = '%'+@search+'%'
      @items = Audio.where("title LIKE ? OR `desc` LIKE ?",searchText,searchText).order('title ASC').paginate(:page => params[:page], :per_page => 10)
    else
      @items = Audio.order('title ASC').paginate(:page => params[:page], :per_page => 10)    
    end    
  end
  
  def music_details
    cid = params[:cid]
    @item = Audio.find(cid)
  end
  
  def removemusic
    cid = params[:cid].to_i
    item = Audio.find(cid)
    item.delete()
    
    flash[:notice] = 'Music was deleted successfully.'
    redirect_to(admin_music_url)
  end
    
  def videos
    
    ## mark all videos featured
    #videos = Video.all
    #videos.each do |video|
      #videoObj = Video.find(video.id)
      #videoObj.update_attributes(:featured => 1)
    #end
    
    @search = params[:search].to_s
    
    if params[:sort_by].present?
      @sort_by = params[:sort_by].to_s
    else
      @sort_by = 'title'
    end
    
    if params[:sort_dir].present?
      @sort_dir = params[:sort_dir].to_s
    else
      @sort_dir = 'asc'
    end
    
    if @search.length > 0
      searchText = '%'+@search+'%'
      @items = Video.where("title LIKE ? OR `desc` LIKE ?",searchText,searchText).paginate(:page => params[:page], :per_page => 10).order(@sort_by + ' ' + @sort_dir.upcase)
    else
      @items = Video.paginate(:page => params[:page], :per_page => 10).order(@sort_by + ' ' + @sort_dir.upcase)
    end    
  end
  
  def video_details
    cid = params[:cid]
    @item = Video.find(cid)
    
    ## fetch video genres
    @video_genres = Array.new(0)
    genres_result = MusicCategoriesVideos.joins("LEFT JOIN `music_categories` ON music_categories.id = music_categories_videos.music_category_id").select("music_categories.*").where("music_categories_videos.video_id = ?",@item.id )
    genres_result.each do |genre|
      @video_genres.push(genre.name)
    end
  end
  
  def save_video
    video = Video.find(video_update_params[:id])
    if video.update(video_update_params)
      flash[:notice] = 'Video was updated successfully.'
      redirect_to(admin_videos_url) and return
    else
      flash[:alert] = 'Video updated failed.'
      redirect_to(admin_video_details_path(:cid=>video_update_params[:id])) and return
    end
  end
  
  def removevideo
    cid = params[:cid].to_i
    item = Video.find(cid)
    item.delete()
    
    flash[:notice] = 'Video was deleted successfully.'
    redirect_to(admin_videos_url)
  end
  
  def make_featured_artist
    artist_id = params[:artist_id].to_i
    value = params[:value].to_i
    artistRow = User.where("id = ? AND user_type = 'artist'",artist_id).take
    if artistRow!=nil
      artistRow.update(:featured=>value)
    end
    flash[:notice] = "Changes successfully made."
    redirect_to(admin_artists_path) and return
  end
  
  def removeuser
    
    user_id = params[:user_id].to_i    
    if user_id == current_user.id
      flash[:alert] = 'You are not authorized to delete yourself.'
      redirect_to(root_path)
    else
      userRow = User.find(user_id);
      
      if userRow != nil 
        if userRow.user_type == 'fan'
          flash[:notice] = "Fan successfully deleted."
          admin_redirect_url = admin_fans_path
          #delete fan rows
          ArtistFans.where('fan_id=?',user_id).delete_all()
        elsif userRow.user_type == 'artist'
          flash[:notice] = "Artist successfully deleted."
          #delete fan rows
          ArtistFans.where('artist_id=?',user_id).delete_all()
          #clear audio
          Audio.where('user_id=?',user_id).delete_all()
          #clear video
          Video.where('user_id=?',user_id).delete_all()
          #clear events
          Event.where('user_id=?',user_id).delete_all()
          #clear news
          News.where('user_id=?',user_id).delete_all()
          #clear friend requests
          Friend.where("sender_id=? OR receiver_id=?",user_id,user_id).delete_all()
          admin_redirect_url = admin_artists_path
        else
          admin_redirect_url = admin_users_path  
        end
        
        #clear Authentication
        Authentication.where('user_id=?',user_id).delete_all()
        #clear Subscription
        Subscription.where('userid=?',user_id).delete_all()
          
        userRow.delete()        
        redirect_to(admin_redirect_url) and return
      end  
    end
  end
  
  def fan
    fan_id = params[:fan_id]
    @fanInfo = User.find(fan_id)
  end
  
  def artist
    artist_id = params[:artist_id]
    @artistInfo = User.find(artist_id)
    @musicCatName = ''
    musicCatRow = MusicCategory.where("id = ? ",@artistInfo.music_catid).take
    if musicCatRow != nil
      @musicCatName = musicCatRow.name
    end
    @fanStats = User.joins('INNER JOIN artist_fans AS af ON af.fan_id = users.id').where("af.artist_id=?",artist_id).select("state_id,COUNT(*) AS fan_count").group("state_id").order('fan_count')
  end
  
  def new_user
    @userInfo = User.new
  end
  
  def edit_user
    user_id = params[:user_id]    
    @userInfo = User.find(user_id)
  end
  
  def save_user
    
    user = User.find(user_update_params[:id])
    params[:user].delete(:password) if params[:user][:password].blank?
    params[:user].delete(:password_confirmation) if params[:user][:password].blank? and params[:user][:password_confirmation].blank?
    
    if !params[:user][:profile_photo].blank?      
        move_tmp_user_photo(user,params[:user][:profile_photo])
    end    
    params[:user].delete(:profile_photo) if params[:user][:profile_photo].blank?
    
    if user.update(user_update_params)
      
      if user.role != "administrator"
        #update geo lat,lon start
        fullAddress = ""
        countryName = ""
        stateName = ""
        if user.country_id.to_i > 0
          countryRow = Country.where("id = ? ",user.country_id.to_i).take
          if countryRow != nil
            countryName = countryRow.country_name
          end
        end
        
        if user.state_id.to_i > 0
          stateRow = State.where("id = ? ",user.state_id.to_i).take
          if stateRow != nil
            stateName = stateRow.state_name
          end
        end
        
        if user.zip.to_s != ""
          fullAddress = user.zip
        end
        
        if user.city.to_s !=""
          if fullAddress.blank?
            fullAddress = user.city
          else
            fullAddress += ","+user.city
          end          
        end
        
        if stateName !=""
          if fullAddress.blank?
            fullAddress = stateName
          else
            fullAddress += ","+stateName
          end          
        end
        
        if countryName !=""
          if fullAddress.blank?
            fullAddress = countryName
          else
            fullAddress += ","+countryName
          end          
        end
        
        if !fullAddress.blank?
          #87456,Tucson,Arizona,United States
          lat_long = Geocoder.coordinates(fullAddress)
          if lat_long!=nil          
            user.update_attributes(:latitude => lat_long[0],:longitude => lat_long[1])
          end        
        end
        #update geo lat,lon end
      end      
      
      flash[:notice] = "Successfully updated User."
      if user.user_type == "artist"
        redirect_to admin_artist_path(:artist_id=>user_update_params[:id])
      elsif user.user_type == "fan"
        redirect_to admin_fan_path(:fan_id=>user_update_params[:id])
      else
        redirect_to admin_users_path
      end
    else
      render :action => 'edit_artist'
    end
  end
  
  #save new admin
  def save_new_user
    @user = User.new(user_update_params)
    @user.role = "administrator"
    respond_to do |format|
      if @user.save
        format.html { redirect_to admin_users_path, notice: 'Admin was successfully created.' }
      else
        format.html { render action: 'new_user' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def settings
    @settings = Settings.find(1)
  end
  
  def save_settings
    @settings = Settings.find(1)
    
    @settings.paypal_merchant_email = params[:paypal_merchant_email]
    @settings.sandbox_merchant_email = params[:sandbox_merchant_email]
    @settings.sandbox = params[:sandbox]
    @settings.currency = params[:currency]
    
    if @settings.save
      flash[:notice] = 'Settings Stored'
    else
      flash[:alert] = 'Failed storing'
    end
    
    redirect_to admin_settings_path
    
  end
  
  private
  def is_admin
    if current_user.role != 'administrator'
      flash[:alert] = 'You are not authorized to view this resource!'
      redirect_to(root_path)
    end
  end
  
  
  def user_update_params
    params.require(:user).permit(:id, :first_name, :last_name,:email, :phone, :biography, :country_id, :state_id, :city, :zip, :profile_photo, :password, :password_confirmation)
  end
  
  def video_update_params
    params.require(:video).permit(:id, :title, :published, :featured, :desc, :source, :remote_path)
  end
  
  def move_tmp_user_photo(userobj,new_photo_name)
    if userobj.profile_photo!=""
      dir = Rails.root.join('public', 'uploads', userobj.class.to_s.underscore)
      # CREATE THE DIRECTORY IF IT DOESNT EXIST
      Dir.mkdir(dir) unless File.exist?(dir)
      
      dir = Rails.root.join('public', 'uploads', userobj.class.to_s.underscore, 'profile_photo')
      # CREATE THE DIRECTORY IF IT DOESNT EXIST
      Dir.mkdir(dir) unless File.exist?(dir)
      
      dir = Rails.root.join('public', 'uploads', userobj.class.to_s.underscore, 'profile_photo', userobj.id.to_s)
      # CREATE THE DIRECTORY IF IT DOESNT EXIST
      Dir.mkdir(dir) unless File.exist?(dir)
      
      #userobj.profile_photo
      if userobj.profile_photo!=nil
        old_path = Rails.root.join('public', 'uploads', userobj.class.to_s.underscore, 'profile_photo', userobj.id.to_s, userobj.profile_photo)
        if File.exists?(old_path)
          File.delete(old_path)
        end
      end
      
      source_path = Rails.root.join('public', 'uploads', 'tmp', new_photo_name)
      target_path = Rails.root.join('public', 'uploads', userobj.class.to_s.underscore, 'profile_photo', userobj.id.to_s, new_photo_name)
      
      #target_path_small = Rails.root.join('public', 'uploads', userobj.class.to_s.underscore, 'profile_photo', userobj.id.to_s, "small_"+new_photo_name)
      #target_path_large = Rails.root.join('public', 'uploads', userobj.class.to_s.underscore, 'profile_photo', userobj.id.to_s, "large_"+new_photo_name)
      
      if File.exist?("#{Rails.root}/public/uploads/tmp/#{new_photo_name}")
        File.rename source_path, target_path
        
        require 'mini_magick'
        buffer = StringIO.new(File.open(target_path,"rb") { |f| f.read })
        image = MiniMagick::Image.read(buffer)
        image.resize "58X58"
        image.write "public/uploads/user/profile_photo/"+userobj.id.to_s+"/small_"+new_photo_name.to_s
        
        buffer = StringIO.new(File.open(target_path,"rb") { |f| f.read })
        image = MiniMagick::Image.read(buffer)
        image.resize "215X215"
        image.write "public/uploads/user/profile_photo/"+userobj.id.to_s+"/large_"+new_photo_name.to_s
        
      end
      
    end
  end
  
end