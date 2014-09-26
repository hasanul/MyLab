module RegistrationHelper
    def get_subscribe_url(user, request)
      url = Rails.env == "production" ? "https://www.paypal.com/cgi-bin/webscr/?" : "https://www.sandbox.paypal.com/cgi-bin/webscr/?"
      url + {
          :cmd => '_ext-enter',
          :redirect_cmd => '_xclick',
          :business => 'delower.hossain@evatix.com', #Email address or account ID of the payment recipient (i.e., the merchant).
          :receiver_email => 'delower.hossain@evatix.com', #Primary email address of the payment recipient (i.e., the merchant
          :order_number => '123456',
          :invoice => '123456',
          :custom => Base64.encode64("123456"),
          :item_name => 'Subscription',
          :amount => 10,
          :currency_code => 'USD',
          :return => root_url,
          :cancel_return => root_url,
          :notify_url => root_url,
          :rm => '2', #the buyer’s browser is redirected to the return URL by using the POST method, and all payment variables are included
	  :no_shipping => 1,
	  :no_note => 1
          
      }.to_query
    end
end
