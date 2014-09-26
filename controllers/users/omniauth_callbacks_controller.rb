class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  
  protect_from_forgery :except => [:confirm_user_provider_signup]
  
  def facebook
    
    auth = request.env['omniauth.auth']
  
    @provider = auth.provider
    @user_email = auth.info.email
    
    ## check if user email exists
    @user = User.where(:email => @user_email).first
      
    # First check if this identity already exists
    @identity = Authentication.find_by_provider_and_uid(auth.provider, auth.uid)
    
    # If no identity was found, create a brand new one here
    if @identity.nil?  
      
      ## if user not found, render a form asking plan, user type etc.
      if @user.nil? 
        
        session[:omniauth] = auth

        render "providers_sign_up"
        
      else ## user is found, so just create a identity
        @identity = Authentication.create(user_id:@user.id,
                                        provider:auth.provider,
                                        uid:auth.uid
                                        )
        
        ## check user subscription
        time = Time.new
        subscribeduser = true
        if @user.role != 'administrator' && @user.user_type == "artist"
          subscribeRow = Subscription.where("userid=?",@user.id).take      
          
          if subscribeRow!= nil
            
            if subscribeRow.status == "Pending"
              lastInvoice = Invoice.where("subscr_id=?",subscribeRow.id).order('id DESC').take
              if lastInvoice!=nil && !lastInvoice.active
                flash[:alert] = "You need to upgrade your subscription."
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
          if subscribeRow != nil
            redirect_to(renew_subscription_path(:subscription_id=>subscribeRow.id)) and return
          else
            redirect_to('/') and return    
          end
        end
        ## subscription check end
        
        ## subscription is alright, so now proceed to login
        if @identity.user.present?
          # The identity we found had a user associated with it so let's 
          # just log them in here
          #self.current_user = @identity.user
          sign_in_and_redirect @identity.user, :event => :authentication #this will throw if @user is not activated
          set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
        else
          # No user associated with the identity so we need to create a new one
          session["devise.facebook_data"] = request.env["omniauth.auth"]
          redirect_to new_user_registration_url
        end
        
      end
    
    else  ## identity already exists
      
      ## check user subscription
      time = Time.new
      subscribeduser = true
      if @user.role != 'administrator' && @user.user_type == "artist"
        subscribeRow = Subscription.where("userid=?",@user.id).take      
        
        if subscribeRow!= nil
          
          if subscribeRow.status == "Pending"
            lastInvoice = Invoice.where("subscr_id=?",subscribeRow.id).order('id DESC').take
            if lastInvoice!=nil && !lastInvoice.active
              flash[:alert] = "You need to upgrade your subscription."
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
        if subscribeRow != nil
          redirect_to(renew_subscription_path(:subscription_id=>subscribeRow.id)) and return
        else
          redirect_to('/') and return    
        end
      end
      ## subscription check end
      
      ## subscription is alright, so now proceed to login
      if user_signed_in?
        if @identity.user == current_user
          # User is signed in so they are trying to link an identity with their
          # account. But we found the identity and the user associated with it 
          # is the current user. So the identity is already associated with 
          # this user. So let's display an error message.
          redirect_to root_url, notice: "Already linked that account!"
        else
          # The identity is not associated with the current_user so lets 
          # associate the identity
          @identity.user = current_user
          @identity.save()
          redirect_to root_url, notice: "Successfully linked that account!"
        end
      else
        if @identity.user.present?
          # The identity we found had a user associated with it so let's 
          # just log them in here
          #self.current_user = @identity.user
          sign_in_and_redirect @identity.user, :event => :authentication #this will throw if @user is not activated
          set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
        else
          # No user associated with the identity so we need to create a new one
          session["devise.facebook_data"] = request.env["omniauth.auth"]
          redirect_to new_user_registration_url
        end
      end
    end
    
  end
  
  def confirm_user_provider_signup
    
    #auth = request.env['omniauth.auth']
    auth = session[:omniauth]
    
    avatar = auth.info.image
    location = auth.info.location
    
    if auth.provider == 'twitter'
      user_email = params[:email]
      first_name = auth.info.name.to_s.split(' ').first
      last_name = auth.info.name.to_s.split(' ').last
      avatar = avatar.sub("_normal", "")
    end
    
    if auth.provider == 'facebook' || auth.provider == 'google_oauth2'
      user_email = auth.info.email
      first_name = auth.info.first_name
      last_name = auth.info.last_name
    end
    
    user_type = params[:user_type]
    plan_id = params[:plan_id]
    
    # Find an identity here
    @identity = Authentication.find_by_provider_and_uid(auth.provider, auth.uid)
  
    if @identity.nil?
      # If no identity was found, create a brand new one here
      user = User.where(:email => user_email).first
      
      user_found = true
      unless user
        user_found = false
        
        generated_password = Devise.friendly_token.first(8)
        user = User.create(email:user_email,
                           first_name:first_name,
                           last_name:last_name,
                           user_type: user_type,
                           plan_id: plan_id,
                            password:generated_password,
                            avatar_url:avatar,
                            confirmed_at: DateTime.now  ## changed: facebook, twitter users should be auto-confirmed, so they won't get confirmation emails - Feb25.2014
                          )
        
        ## send welcome email to this new user for free subscription
        ## paid subscription users will get email after they pay
        
        ## changed: all users will get confirmation email right after they sign up
        
        #@plan = Plan.find(user.plan_id)
        #if @plan.is_free
          #UsersMailer.welcome_message(user, generated_password).deliver
        #end
      end
    
      @identity = Authentication.create(user_id:user.id,
                                        provider:auth.provider,
                                        uid:auth.uid
                                        )
      
      
      ## create a subscription for this new user
      if user_found==false
    
        @subscription = Subscription.new
        @subscription.userid = user.id
        @subscription.signup_date = user.created_at
        @subscription.plan = user.plan_id
        
        signup_date = DateTime.parse(user.created_at.to_s)
        
        if user.user_type == 'artist'
          
          @plan = Plan.find(user.plan_id)
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
        
        ## if plan is not free, create an invoice and redirect user to paypal
        if user.user_type == 'artist'
          
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
            
            # redirect to paypal
            settings = Settings.find(1);
            paypal_url = settings.sandbox ? "https://www.sandbox.paypal.com/cgi-bin/webscr" : "https://www.paypal.com/cgi-bin/webscr"
            merchant_email = settings.sandbox ? settings.sandbox_merchant_email : settings.paypal_merchant_email
            currency_3_code = settings.currency.to_s == "" ? 'USD' : settings.currency
            
            post_vars = {
                  :cmd => '_ext-enter',
                  :redirect_cmd => '_xclick',
                  :business => merchant_email, #Email address or account ID of the payment recipient (i.e., the merchant).
                  :receiver_email => merchant_email, #Primary email address of the payment recipient (i.e., the merchant
                  :order_number => @invoice.invoice_number,
                  :invoice => @invoice.invoice_number,
                  :custom => Base64.encode64("#{user_email}|#{user.encrypted_password}"),
                  :item_name => "Artist Subscription - #{@plan.name}",
                  :amount => @plan.price,
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
            paypal_form += '</form></div>';
            paypal_form += '<script type="text/javascript">';
            paypal_form += 'document.getElementById( "paypal_submit_trigger" ).click();';
            paypal_form += '</script>';
            paypal_form += '</body></html>';
            
            render text: paypal_form and return
          end
        end
        
      else ## updating user for twitter provider, check subscription status
        
        time = Time.new
        subscribeduser = true
        if user.role != 'administrator' && user.user_type == "artist"
          subscribeRow = Subscription.where("userid=?",user.id).take      
          
          if subscribeRow!= nil
            
            if subscribeRow.status == "Pending"
              lastInvoice = Invoice.where("subscr_id=?",subscribeRow.id).order('id DESC').take
              if lastInvoice!=nil && !lastInvoice.active
                flash[:alert] = "You need to upgrade your subscription."
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
          if subscribeRow != nil
            redirect_to(renew_subscription_path(:subscription_id=>subscribeRow.id)) and return
          else
            redirect_to('/') and return    
          end
        end
        ## subscription check end
        
      end
      
    end
  
    if user_signed_in?
      if @identity.user == current_user
        # User is signed in so they are trying to link an identity with their
        # account. But we found the identity and the user associated with it 
        # is the current user. So the identity is already associated with 
        # this user. So let's display an error message.
        redirect_to root_url, notice: "Already linked that account!"
      else
        # The identity is not associated with the current_user so lets 
        # associate the identity
        @identity.user = current_user
        @identity.save()
        redirect_to root_url, notice: "Successfully linked that account!"
      end
    else
      if @identity.user.present?
        # The identity we found had a user associated with it so let's 
        # just log them in here
        #self.current_user = @identity.user
        sign_in_and_redirect @identity.user, :event => :authentication #this will throw if @user is not activated
        set_flash_message(:notice, :success, :kind => auth.provider.to_s.capitalize) if is_navigational_format?
      else
        # No user associated with the identity so we need to create a new one
        session["devise.facebook_data"] = request.env["omniauth.auth"]
        redirect_to new_user_registration_url
      end
    end
    
  end
  
  def twitter
    
    auth = request.env['omniauth.auth']
    
    @provider = auth.provider
    
    ## twitter does not provide user email
    #@user_email = auth.info.email
    
    ## check if user email exists
    #@user = User.where(:email => @user_email).take
      
    # First check if this identity already exists
    @identity = Authentication.find_by_provider_and_uid(auth.provider, auth.uid)
    
    # If no identity was found, create a brand new one here
    if @identity.nil?  
      
      ## if user not found, render a form asking plan, user type etc.
        session[:omniauth] = auth
        render "providers_sign_up"
    
    else  ## identity already exists
      
      @user = User.find(@identity.user_id )
      
      ## first check user subscription 
      time = Time.new
      subscribeduser = true
      if @user.role != 'administrator' && @user.user_type == "artist"
        subscribeRow = Subscription.where("userid=?",@user.id).take      
        
        if subscribeRow!= nil
          
          if subscribeRow.status == "Pending"
            lastInvoice = Invoice.where("subscr_id=?",subscribeRow.id).order('id DESC').take
            if lastInvoice!=nil && !lastInvoice.active
              flash[:alert] = "You need to upgrade your subscription."
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
        if subscribeRow != nil
          redirect_to(renew_subscription_path(:subscription_id=>subscribeRow.id)) and return
        else
          redirect_to('/') and return    
        end
      end
      ## subscription check end
      
      ## subscription is alright, so now proceed to login
      if user_signed_in?
        if @identity.user == current_user
          # User is signed in so they are trying to link an identity with their
          # account. But we found the identity and the user associated with it 
          # is the current user. So the identity is already associated with 
          # this user. So let's display an error message.
          redirect_to root_url, notice: "Already linked that account!"
        else
          # The identity is not associated with the current_user so lets 
          # associate the identity
          @identity.user = current_user
          @identity.save()
          redirect_to root_url, notice: "Successfully linked that account!"
        end
      else
        if @identity.user.present?
          # The identity we found had a user associated with it so let's 
          # just log them in here
          #self.current_user = @identity.user
          sign_in_and_redirect @identity.user, :event => :authentication #this will throw if @user is not activated
          set_flash_message(:notice, :success, :kind => "Twitter") if is_navigational_format?
        else
          # No user associated with the identity so we need to create a new one
          session["devise.twitter_data"] = request.env["omniauth.auth"]
          redirect_to new_user_registration_url
        end
      end
    end
    
  end
  
  
  def google_oauth2
    auth = request.env['omniauth.auth']
    
    @provider = auth.provider
    @user_email = auth.info.email
    
    ## check if user email exists
    @user = User.where(:email => @user_email).first
      
    # First check if this identity already exists
    @identity = Authentication.find_by_provider_and_uid(auth.provider, auth.uid)
    
    # If no identity was found, create a brand new one here
    if @identity.nil?  
      
      ## if user not found, render a form asking plan, user type etc.
      if @user.nil? 
        
        session[:omniauth] = auth

        render "providers_sign_up"
        
      else ## user is found, so just create a identity
        @identity = Authentication.create(user_id:@user.id,
                                        provider:auth.provider,
                                        uid:auth.uid
                                        )
        
        ## check user subscription
        time = Time.new
        subscribeduser = true
        if @user.role != 'administrator' && @user.user_type == "artist"
          subscribeRow = Subscription.where("userid=?",@user.id).take      
          
          if subscribeRow!= nil
            
            if subscribeRow.status == "Pending"
              lastInvoice = Invoice.where("subscr_id=?",subscribeRow.id).order('id DESC').take
              if lastInvoice!=nil && !lastInvoice.active
                flash[:alert] = "You need to upgrade your subscription."
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
          if subscribeRow != nil
            redirect_to(renew_subscription_path(:subscription_id=>subscribeRow.id)) and return
          else
            redirect_to('/') and return    
          end
        end
        ## subscription check end
        
        ## subscription is alright, so now proceed to login
        if @identity.user.present?
          # The identity we found had a user associated with it so let's 
          # just log them in here
          #self.current_user = @identity.user
          sign_in_and_redirect @identity.user, :event => :authentication #this will throw if @user is not activated
          set_flash_message(:notice, :success, :kind => "Google") if is_navigational_format?
        else
          # No user associated with the identity so we need to create a new one
          session["devise.google_data"] = request.env["omniauth.auth"]
          redirect_to new_user_registration_url
        end
        
      end
    
    else  ## identity already exists
      
      ## check user subscription
      time = Time.new
      subscribeduser = true
      if @user.role != 'administrator' && @user.user_type == "artist"
        subscribeRow = Subscription.where("userid=?",@user.id).take      
        
        if subscribeRow!= nil
          
          if subscribeRow.status == "Pending"
            lastInvoice = Invoice.where("subscr_id=?",subscribeRow.id).order('id DESC').take
            if lastInvoice!=nil && !lastInvoice.active
              flash[:alert] = "You need to upgrade your subscription."
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
        if subscribeRow != nil
          redirect_to(renew_subscription_path(:subscription_id=>subscribeRow.id)) and return
        else
          redirect_to('/') and return    
        end
      end
      ## subscription check end
      
      ## subscription is alright, so now proceed to login
      if user_signed_in?
        if @identity.user == current_user
          # User is signed in so they are trying to link an identity with their
          # account. But we found the identity and the user associated with it 
          # is the current user. So the identity is already associated with 
          # this user. So let's display an error message.
          redirect_to root_url, notice: "Already linked that account!"
        else
          # The identity is not associated with the current_user so lets 
          # associate the identity
          @identity.user = current_user
          @identity.save()
          redirect_to root_url, notice: "Successfully linked that account!"
        end
      else
        if @identity.user.present?
          # The identity we found had a user associated with it so let's 
          # just log them in here
          #self.current_user = @identity.user
          sign_in_and_redirect @identity.user, :event => :authentication #this will throw if @user is not activated
          set_flash_message(:notice, :success, :kind => "Google") if is_navigational_format?
        else
          # No user associated with the identity so we need to create a new one
          session["devise.google_data"] = request.env["omniauth.auth"]
          redirect_to new_user_registration_url
        end
      end
    end
    
  end
  
end