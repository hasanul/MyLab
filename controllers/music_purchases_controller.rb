class MusicPurchasesController < ApplicationController
  before_action :set_music_order, only: [:show, :edit, :update, :destroy, :complete_order]
  before_filter :authenticate_user!
  before_filter :is_admin
  protect_from_forgery except: [:set_expiration_date,:set_subscription_status]
  layout 'admin_layouts'

  # GET /plans
  # GET /plans.json
  def index
    @search = params[:search].to_s
    @status = params[:status].to_s
    @artist = params[:artist].to_s
    @purchase_date_start = params[:purchase_date_start].to_s
    @purchase_date_end = params[:purchase_date_end].to_s
    @music_orders = Order.joins('INNER JOIN users AS u ON u.id=orders.user_id').joins('INNER JOIN order_items AS oi ON oi.order_id=orders.id').joins('INNER JOIN audios ON audios.id=oi.product_id')
    if @search.length > 0
      searchText = '%'+@search+'%'
      @music_orders = @music_orders.where("CONCAT(u.first_name,' ',u.last_name) LIKE ?",searchText)    
    end
    if @artist!=""
      @music_orders = @music_orders.where("audios.user_id=?",@artist)
      #@music_orders = Order.joins('INNER JOIN audios ON audios.id=oi.product_id')
    end
    if @status == "Complete"
      @music_orders = @music_orders.where("order_status=1")
    elsif @status == "Incomplete"
      @music_orders = @music_orders.where("order_status=0")
    end
    
    if @purchase_date_start!=""
      @music_orders = @music_orders.where("date(created_at)>=?",@purchase_date_start)
    end
    if @purchase_date_end!=""
      @music_orders = @music_orders.where("date(created_at)<=?",@purchase_date_end)
    end
    @music_orders = @music_orders.order('created_at DESC').paginate(:page => params[:page], :per_page => 10)
    #render text: @music_orders.to_sql
  end

  # GET /plans/1
  # GET /plans/1.json
  def show
    #render text: @music_order.order_items.length and return
  end

  
  def complete_order
    if @music_order.order_status == 0
      @music_order.order_status = 1
      @music_order.save()
      if @music_order.order_items != nil
        @music_order.order_items.each do |order_item|
          order_item.order_status = 1
          order_item.save()
        end
      end
      flash[:notice] = 'Order status successfully updated'
    else
      flash[:alert] = 'Order is already completed!'
    end    
    redirect_to music_purchases_path
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_music_order
      @music_order = Order.find(params[:id])      
    end
    
    def is_admin
      if current_user.role != 'administrator'
        flash[:alert] = 'You are not authorized to view this resource!'
        redirect_to(root_path)
      end
    end
    
end
