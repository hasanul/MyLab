class ProfileController < ApplicationController
  before_filter :authenticate_user!
  before_filter :is_user_artist?, only: [:follower_fans, :my_music_sales]
  before_filter :is_user_fan?, only: [:add_friend,:remove_friend,:accept_friend_request,:my_friends]
  def index
    if current_user.country_id != nil
      @country = Country.find(current_user.country_id)
      @country_name = @country.country_name
    else
      @country_name = ""
    end
    
    if current_user.state_id != nil
      @state = State.find(current_user.state_id)
      @state_name = @state.state_name
    else
      @state_name = ""
    end
      
    if current_user.user_type == 'artist'
      render "index"
    elsif current_user.user_type == 'fan'
      fan_user_name = current_user.first_name+' '+current_user.last_name
      redirect_to fan_dashboard_path(id: current_user.id.to_s+':'+fan_user_name.parameterize)  and return
    end
  end
  
  def upload_image
  end

  def follower_fans    
    #fans following me
    @pageNo = params[:page]
  end
  
  def artist_following
    #artist i am following
    @pageNo = params[:page]
  end

  def settings
  end
  def my_musics
    @purchasedMusics = OrderItem.joins('INNER JOIN orders ON order_items.order_id = orders.id').where("orders.user_id=? AND orders.order_status=1 AND order_items.order_status=1",current_user.id).order('order_items.created_at DESC')    
  end
  
  def my_purchases
    @myPurchases = Order.where("user_id=?",current_user.id).order('created_at DESC')
  end
  
  def my_music_sales
    @myMusicOrders = OrderItem.joins('INNER JOIN audios ON order_items.product_id = audios.id').where("audios.user_id=? AND order_items.order_status=1",current_user.id).select("order_items.product_id,COUNT(*) AS sold").group("order_items.product_id").order('sold DESC')    
  end
  
  def favorite_videos
    @pageNo = params[:page]
  end
  
  def watch_history
    @pageNo = params[:page]
  end
  
  def my_order_details
    id = params[:id]
    @myPurchasDetails = Order.where("user_id=? AND order_number=?",current_user.id,id).take    
    if @myPurchasDetails == nil
      redirect_to root_path, notice: '404 order does not exist.'    
    end
  end
  
  def pay_my_order
    id = params[:id]
    @myPurchasDetails = Order.where("user_id=? AND order_number=?",current_user.id,id).take    
    if @myPurchasDetails == nil
      redirect_to root_path, notice: '404 order does not exist.'    
    end
    
    settings = Settings.find(1);
    paypal_url = settings.sandbox ? "https://www.sandbox.paypal.com/cgi-bin/webscr" : "https://www.paypal.com/cgi-bin/webscr"
    merchant_email = settings.sandbox ? settings.sandbox_merchant_email : settings.paypal_merchant_email 
    currency_3_code = settings.currency=="" ? 'USD' : settings.currency
    
    # create order items entry
    item_hidden_field = '';
    
    @myPurchasDetails.order_items.each_with_index do |item, index|
      # create item rows for paypal
      item_hidden_field += "<input type='hidden' name='item_name_"+(index+1).to_s+"' value='"+item.product_name.to_s+"' />";
      item_hidden_field += "<input type='hidden' name='amount_"+(index+1).to_s+"' value='"+item.product_final_price.round(2).to_s+"' />";
      item_hidden_field += "<input type='hidden' name='quantity_"+(index+1).to_s+"' value='"+item.product_quantity.to_s+"' />";
    end
    post_vars = {
          :cmd => '_cart',
          :upload => '1',
          :business => merchant_email, #Email address or account ID of the payment recipient (i.e., the merchant).
          :receiver_email => merchant_email, #Primary email address of the payment recipient (i.e., the merchant
          :order_number => @myPurchasDetails.order_number,
          :invoice => @myPurchasDetails.order_number,
          :custom => Base64.encode64("Music Purchase"),
          #:item_name => "Music Purchase",
          :amount => @myPurchasDetails.order_total.round(2),
          :currency_code => currency_3_code,
          :return => root_url,
          :cancel_return => root_url,
          :notify_url => payment_notifications_url,
          :rm => '2', #the buyer’s browser is redirected to the return URL by using the POST method, and all payment variables are included
          :no_shipping => 1,
          :no_note => 1
    }
    paypal_form = '<html><head><title>Redirection</title><head></head><body><div style="margin: auto; text-align: center;">'
    paypal_form += "<form action='#{paypal_url}' method='post' name='paypal_form' id='paypal_form'>";
    paypal_form += '<input type="submit" id="paypal_submit_trigger" value="Please wait while redirecting to PayPal" />';
    
    post_vars.each {|key, value|
        paypal_form += "<input type='hidden' name='#{key}' value='#{value}' />";
    }
    
    paypal_form += item_hidden_field
    
    paypal_form += '</form></div>';
    paypal_form += '<script type="text/javascript">';
    paypal_form += 'document.getElementById( "paypal_submit_trigger" ).click();';
    paypal_form += '</script>';
    paypal_form += '</body></html>';
    render text:paypal_form and return
  end
  
  def add_friend
    sender_id = params[:sender_id]
    receiver_id = params[:receiver_id]
    
    receiverUser = User.where("id=? AND user_type='fan'",receiver_id).take
    senderUser = User.where("id=? AND user_type='fan'",sender_id).take
    if receiverUser.nil? || senderUser.nil? || (current_user.id!=receiverUser.id && current_user.id!=senderUser.id)
      redirect_to root_path, notice: 'Invalid request.'
    else
      friendRequestRow = Friend.where("(sender_id=? AND receiver_id=?) OR (sender_id=? AND receiver_id=?)",sender_id,receiver_id,receiver_id,sender_id)
      if friendRequestRow.length.eql?(0)
        newFriendRequest = Friend.new
        newFriendRequest.sender_id = sender_id
        newFriendRequest.receiver_id = receiver_id
        newFriendRequest.status = 0
        newFriendRequest.save
        fan_user_name = receiverUser.first_name + " " + receiverUser.last_name
        if !params[:return_url].blank?
          redirect_to Base64.decode64(params[:return_url]), notice: 'Friend request sent successfully.' and return
        else
          redirect_to fan_dashboard_path(id: receiverUser.id.to_s+':'+fan_user_name.parameterize), notice: 'Friend request sent successfully.'  
        end        
      else
        redirect_to root_path, notice: 'Friend request already sent.'
      end
    end    
  end
  
  def remove_friend
    sender_id = params[:sender_id]
    receiver_id = params[:receiver_id]    
    receiverUser = User.where("id=? AND user_type='fan'",receiver_id).take
    senderUser = User.where("id=? AND user_type='fan'",sender_id).take
    if receiverUser.nil? || senderUser.nil? || (current_user.id!=receiverUser.id && current_user.id!=senderUser.id)
      redirect_to root_path, notice: 'Invalid request.'
    else
      friendRequestRow = Friend.where("(sender_id=? AND receiver_id=?) OR (sender_id=? AND receiver_id=?)",sender_id,receiver_id,receiver_id,sender_id)
      if !friendRequestRow.length.eql?(0)
        Friend.where("(sender_id=? AND receiver_id=?) OR (sender_id=? AND receiver_id=?)",sender_id,receiver_id,receiver_id,sender_id).destroy_all
        fan_user_name = receiverUser.first_name + " " + receiverUser.last_name
        if !params[:return_url].blank?
          redirect_to Base64.decode64(params[:return_url]), notice: 'Removed successfully.' and return
        else
          redirect_to fan_dashboard_path(id: receiverUser.id.to_s+':'+fan_user_name.parameterize), notice: 'Removed successfully.' and return  
        end
      else
        redirect_to root_path, notice: 'No friend request was sent'
      end
    end    
  end
  
  def accept_friend_request
    sender_id = params[:sender_id]
    receiver_id = params[:receiver_id]
    
    receiverUser = User.where("id=? AND user_type='fan'",receiver_id).take
    senderUser = User.where("id=? AND user_type='fan'",sender_id).take
    if receiverUser.nil? || senderUser.nil? || (current_user.id!=receiverUser.id && current_user.id!=senderUser.id)
      redirect_to root_path, notice: 'Invalid request.'
    else
      friendRequestRow = Friend.where("(sender_id=? AND receiver_id=? AND status=0)",sender_id,receiver_id).take
      if !friendRequestRow.nil?
        friendRequestRow.status = 1
        friendRequestRow.save
        fan_user_name = senderUser.first_name + " " + senderUser.last_name
        if !params[:return_url].blank?
          redirect_to Base64.decode64(params[:return_url]), notice: 'Friendship request accepted successfully.' and return
        else
          redirect_to fan_dashboard_path(id: senderUser.id.to_s+':'+fan_user_name.parameterize), notice: 'Friendship request accepted successfully.'  
        end        
      else
        redirect_to root_path, notice: 'No pending friend request found'
      end
    end
  end
  
  def my_friends
    @myFriendsTotal = Friend.where("(sender_id=? OR receiver_id=?) AND status=1",current_user.id,current_user.id).count()
    @myFriends = Friend.where("(sender_id=? OR receiver_id=?) AND status=1",current_user.id,current_user.id).order('created_at DESC').paginate(:page => params[:page], :per_page => 10)        
  end
  
  def peding_friend_requests
    @total = Friend.where("receiver_id=? AND status=0",current_user.id).count()
    @myPendingFriendRequests = Friend.where("receiver_id=? AND status=0",current_user.id).order('created_at DESC').paginate(:page => params[:page], :per_page => 10)        
  end
  
  def awaiting_friend_requests
    @total = Friend.where("sender_id=? AND status=0",current_user.id).count()
    @myAwaitingFriendRequests = Friend.where("sender_id=? AND status=0",current_user.id).order('created_at DESC').paginate(:page => params[:page], :per_page => 10)        
  end
  
end
