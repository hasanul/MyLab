class Users::SessionsController < Devise::SessionsController
  
  before_filter :update_last_seen, only: :destroy
  
  def update_last_seen
    loggedInUser = User.find(current_user.id)
    loggedInUser.update(:lastlogintime=>0)
  end
  
  # POST /resource/sign_in
  def create
    
    
    self.resource = warden.authenticate!(auth_options)
    #already logged in
    time = Time.new
    subscribeduser = true
    if self.resource.role != 'administrator' && self.resource.user_type == "artist"
      subscribeRow = Subscription.where("userid=?",self.resource.id).take      
      if subscribeRow!= nil
        if subscribeRow.status == "Pending"
          lastInvoice = Invoice.where("subscr_id=?",subscribeRow.id).order('id DESC').take
          if lastInvoice!=nil && !lastInvoice.active
            sign_out self.resource
            flash[:alert] = "Your subscription is not activated yet."
            redirect_to(pending_invoice_path(:subscription_id=>subscribeRow.id)) and return
          end
        end
        if subscribeRow.status!="Active"
          flash[:alert] = "You need to confirm your subscription."
          subscribeduser = false
        elsif !subscribeRow.lifetime && (subscribeRow.expiration.to_time.utc < time.strftime("%Y-%m-%d %H:%M:%S"))
          flash[:alert] = "Your subscription is expired. Please choose any subscriptions below."
          subscribeduser = false
        end
      else
        subscribeduser = false
      end
    end
    
    
    if subscribeduser == false      
      sign_out self.resource
      
      if subscribeRow != nil
        redirect_to(renew_subscription_path(:subscription_id=>subscribeRow.id)) and return
      else
        redirect_to('/') and return    
      end      
    end
    
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    #check if cart items in session
    if session[:music_cart] != nil
      previous_cart = Cart.where(:user_id => self.resource.id).first
      
      unless previous_cart
      previous_cart = Cart.create(user_id:self.resource.id,
                           cart_number:SecureRandom.uuid,
                           cart_total:'0',
                           ip_address: request.remote_ip
                          )
      end
      
      session[:music_cart].each do |cart_item_row|
        product = Audio.find(cart_item_row[:product_id])
        if product!=nil
          # check if this product is already added
          # If yes, update quantity 
          previous_cart_item = CartItem.where(:cart_id => previous_cart.id, :product_id => cart_item_row[:product_id]).first
          
          if previous_cart_item==nil
            previous_cart_item = CartItem.create(cart_id: previous_cart.id,
                                 product_id: cart_item_row[:product_id],
                                 product_name: cart_item_row[:product_name],
                                 quantity: 1,
                                 product_price: cart_item_row[:product_final_price],
                                 product_final_price: cart_item_row[:product_final_price]
                                )
          end            
        end
      end
      #session[:music_cart] = nil
    end
    #temp cart handler end ..
    if params[:return_url]!=nil
      respond_with resource, :location => Base64.decode64(params[:return_url]) 
    else
      if self.resource.user_type.eql?("fan")
        fan_username = self.resource.first_name + " " + self.resource.last_name
        profileLink = fan_dashboard_path(id: self.resource.id.to_s+':'+fan_username.parameterize)
        respond_with resource, :location => profileLink
      else
        respond_with resource, :location => after_sign_in_path_for(resource)       
      end      
    end
  end
    
end
