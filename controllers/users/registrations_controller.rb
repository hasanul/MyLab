class Users::RegistrationsController < Devise::RegistrationsController
  
  before_filter :set_user_type, :only => [:new, :create]
  include RegistrationHelper
  
  def new
    
    @user_type = params[:user][:user_type]
    
    build_resource
  end
  
  
  # POST /resource
  def create
    
    # Getting the user type that is send through a hidden field in the registration form.
    @user_type = params[:user][:user_type]
    
    build_resource(sign_up_params)

    if resource.save
      yield resource if block_given?
      
      ## Move the user profile photo from tmp to user directory
      if resource.profile_photo!=""
        move_tmp_user_photo(resource)
      end
      
      ## create a subscription for this user
      @subscription = Subscription.new
      @subscription.userid = resource.id
      @subscription.signup_date = resource.created_at
      @subscription.plan = resource.plan_id
      
      signup_date = DateTime.parse(resource.created_at.to_s)
      
      if resource.user_type == 'artist'
        
        @plan = Plan.find(resource.plan_id)
        if @plan.is_free
          @subscription.subscr_method = 'free'
          @subscription.status = 'Active'
          @subscription.recurring = 0
          @subscription.lifetime = 1
        else
          @subscription.subscr_method = 'paypal'
          @subscription.status = 'Pending'
          @subscription.recurring = 1
          @subscription.lifetime = 0
          @subscription.expiration = signup_date.advance(months:1).to_datetime
        end
        
      else
        @subscription.subscr_method = 'free'
        @subscription.status = 'Active'
        @subscription.recurring = 0
        @subscription.lifetime = 1
      end
      
      @subscription.save
      
      
      
      ## co-ordinate calculation from user location
      #if resource.user_type == 'fan' #//save latitude longitude
        fullAddress = ""
        countryName = ""
        stateName = ""
        if resource.country_id.to_i > 0
          countryRow = Country.where("id = ? ",resource.country_id.to_i).take
          if countryRow != nil
            countryName = countryRow.country_name
          end
        end
        
        if resource.state_id.to_i > 0
          stateRow = State.where("id = ? ",resource.state_id.to_i).take
          if stateRow != nil
            stateName = stateRow.state_name
          end
        end
        
        if resource.zip.to_s != ""
          fullAddress = URI.encode(resource.zip)
        end
        
        if resource.city.to_s !=""
          if fullAddress.blank?
            fullAddress = URI.encode(resource.city)
          else
            fullAddress += ","+URI.encode(resource.city)
          end          
        end
        
        if stateName !=""
          if fullAddress.blank?
            fullAddress = URI.encode(stateName)
          else
            fullAddress += ","+URI.encode(stateName)
          end          
        end
        
        if countryName !=""
          if fullAddress.blank?
            fullAddress = URI.encode(countryName)
          else
            fullAddress += ","+URI.encode(countryName)
          end          
        end        
        if !fullAddress.blank?
          lat_long = Geocoder.coordinates(fullAddress)
          if !lat_long.nil?
            cUser = User.find(resource.id);
            cUser.update_attributes(:latitude => lat_long[0],:longitude => lat_long[1])
          end          
        end
      #end
      
      ## if plan is not free, create an invoice and redirect user to paypal
      if resource.user_type == 'artist'
        
        ## send profile confirmation URL to user
        #User.find(resource.id).send_confirmation_instructions
        
        if !@plan.is_free
          @invoice = Invoice.new
          @invoice.userid = @subscription.userid
          @invoice.subscr_id = @subscription.id
          @invoice.active = 0
          @invoice.invoice_number = SecureRandom.uuid
          @invoice.created_date = Time.now.to_datetime.utc
          @invoice.used_plan = @subscription.plan
          @invoice.method = 'paypal'
          @invoice.amount = @plan.price
          @invoice.currency = 'USD'          
          @invoice.save          
          
          redirect_to(pending_invoice_path(:subscription_id=>@subscription.id)) and return
        end
      end
      
      #save the music if exist
      if !resource.music_source_youtube.blank? && !resource.music_info.blank? && !resource.music_catid.blank?
        @video = Video.new
        @video.user_id = resource.id
        @video.title = resource.music_info
        @video.desc = resource.music_desc
        @video.source = "remote"
        @video.remote_path = resource.music_source_youtube
        @video.published = 1
        if @video.save && !@video.nil?
          MusicCategoriesVideos.create(:music_category_id => resource.music_catid,:video_id=>@video.id)
        end
      end
      
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      respond_with resource
    end
  end
  
  def edit
    @user_identity = Authentication.find_by user_id: current_user.id
  end
  
    # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    
    oldUser = User.find(current_user.id)
    @user = User.find(current_user.id)

    successfully_updated = if needs_password?(@user, account_update_params)
      @user.update_with_password(account_update_params)
    else
      # remove the virtual current_password attribute update_without_password
      # doesn't know how to ignore it
      params[:user].delete(:current_password)
      @user.update_without_password(account_update_params)
    end

    if successfully_updated
      
      ## Move the user profile photo from tmp to user directory
      if @user.profile_photo!=""
        move_tmp_user_photo(@user)
      end
      
      #update latitude longitude here ...
      if @user.user_type == "fan" || @user.user_type == "artist"
        #//check if the address has been changed
        addressChanged = !((oldUser.country_id == @user.country_id) && (oldUser.state_id == @user.state_id) && (oldUser.zip ==@user.zip) && (oldUser.city == @user.city))
        if addressChanged
          fullAddress = ""
          countryName = ""
          stateName = ""
          if @user.country_id.to_i > 0
            countryRow = Country.where("id = ? ",@user.country_id.to_i).take
            if countryRow != nil
              countryName = countryRow.country_name
            end
          end
          
          if @user.state_id.to_i > 0
            stateRow = State.where("id = ? ",@user.state_id.to_i).take
            if stateRow != nil
              stateName = stateRow.state_name
            end
          end
          
          if @user.zip.to_s != ""
            fullAddress = URI.encode(@user.zip)
          end
          
          if @user.city.to_s !=""
            if fullAddress.blank?
              fullAddress = URI.encode(@user.city)
            else
              fullAddress += ","+URI.encode(@user.city)
            end          
          end
          
          if stateName !=""
            if fullAddress.blank?
              fullAddress = URI.encode(stateName)
            else
              fullAddress += ","+URI.encode(stateName)
            end          
          end
          
          if countryName !=""
            if fullAddress.blank?
              fullAddress = URI.encode(countryName)
            else
              fullAddress += ","+URI.encode(countryName)
            end          
          end
          
          #render text: fullAddress and return
          if !fullAddress.blank?
            lat_long = Geocoder.coordinates(fullAddress)
            cUser = User.find(@user.id);
            if lat_long!=nil
              cUser.update_attributes(:latitude => lat_long[0],:longitude => lat_long[1])
            end            
          end        
        end        
      end
      
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to after_update_path_for(@user)
    else
      render "edit"
    end
  end
  
  #check unqiue email
  def check_email
    "Ajax is here";
  end
  
  private

    # check if we need password to update user data
    # ie if password or email was changed
    # extend this as needed
    def needs_password?(user, params)
      user.email != params[:email] ||
        params[:password].present?
    end
    
  protected

    def set_user_type
      params[:user][:user_type] ||= "artist"
    end
   
    # The path used after sign up. You need to overwrite this method
    # in your own RegistrationsController.
    def after_sign_up_path_for(resource)
      after_sign_in_path_for(resource)
    end
  
    # The path used after sign up for inactive accounts. You need to overwrite
    # this method in your own RegistrationsController.
    def after_inactive_sign_up_path_for(resource)
      respond_to?(:root_path) ? root_path : "/"
    end
  
    # The default url to be used after updating a resource. You need to overwrite
    # this method in your own RegistrationsController.
    def after_update_path_for(resource)      
      profile_index_path()
    end
  
    def sign_up_params
      params.require(:user).permit(:email,:password,:password_confirmation,:user_type,:plan_id,:first_name,:last_name,:phone,:music_info,:music_catid,:music_desc,:music_label,:profile_photo,:music_source_local,:music_source_youtube,:country_id,:state_id,:city,:zip,:provider,:uid,:name)
    end
  
    def account_update_params
      params.require(:user).permit(:email,:password,:password_confirmation,:current_password,:user_type,:plan_id,:first_name,:last_name,:phone,:biography,:music_info,:music_catid,:music_desc,:music_label,:profile_photo,:music_source_local,:music_source_youtube,:country_id,:state_id,:city,:zip)
    end
    
    ## Move the user profile photo from tmp to user directory if user uploaded profile photo
    def move_tmp_user_photo(resource)
      if resource.profile_photo!=""
        
        dir = Rails.root.join('public', 'uploads', resource.class.to_s.underscore)
        # CREATE THE DIRECTORY IF IT DOESNT EXIST
        Dir.mkdir(dir) unless File.exist?(dir)
        
        dir = Rails.root.join('public', 'uploads', resource.class.to_s.underscore, 'profile_photo')
        # CREATE THE DIRECTORY IF IT DOESNT EXIST
        Dir.mkdir(dir) unless File.exist?(dir)
        
        dir = Rails.root.join('public', 'uploads', resource.class.to_s.underscore, 'profile_photo', resource.id.to_s)
        # CREATE THE DIRECTORY IF IT DOESNT EXIST
        Dir.mkdir(dir) unless File.exist?(dir)
        
        source_path = Rails.root.join('public', 'uploads', 'tmp', resource.profile_photo)
        random_token = Digest::SHA2.hexdigest("#{Time.now.utc}").first(20)
        fileExt = File.extname(resource.profile_photo)
        imageName = resource.first_name.to_s.downcase+"_"+random_token+fileExt
        imageName = File.basename(imageName)         
        imageName.sub(/[^\w\.\-]/,'_')
        
        target_path = Rails.root.join('public', 'uploads', resource.class.to_s.underscore, 'profile_photo', resource.id.to_s, imageName)
        #target_path_small = Rails.root.join('public', 'uploads', resource.class.to_s.underscore, 'profile_photo', resource.id.to_s, "small_"+imageName)
        #target_path_large = Rails.root.join('public', 'uploads', resource.class.to_s.underscore, 'profile_photo', resource.id.to_s, "large_"+imageName)
        
        if File.exist?("#{Rails.root}/public/uploads/tmp/#{resource.profile_photo}")
          File.rename source_path, target_path
          
          require 'mini_magick'
          
          ## crop image
          image = MiniMagick::Image.open(target_path)
          image.crop("#{params[:crop_w].to_s}X#{params[:crop_h].to_s}+#{params[:crop_x1].to_s}+#{params[:crop_y1].to_s}")
          image.write "public/uploads/user/profile_photo/"+resource.id.to_s+"/"+imageName.to_s
          
          ## resize the new cropped image
          buffer = StringIO.new(File.open(target_path,"rb") { |f| f.read })
          image = MiniMagick::Image.read(buffer)
          image.resize "58X58"
          image.write "public/uploads/user/profile_photo/"+resource.id.to_s+"/small_"+imageName.to_s
          
          buffer = StringIO.new(File.open(target_path,"rb") { |f| f.read })
          image = MiniMagick::Image.read(buffer)
          image.resize "215X215"
          image.write "public/uploads/user/profile_photo/"+resource.id.to_s+"/large_"+imageName.to_s
          
          resource.profile_photo = imageName
          resource.save()
        end
        
      end
    end
    
end
