class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!
  before_filter :is_admin
  protect_from_forgery except: [:set_expiration_date,:set_subscription_status]
  layout 'admin_layouts'

  # GET /plans
  # GET /plans.json
  def index
    @search = params[:search].to_s
    @status = params[:status].to_s
    @plan = params[:plan].to_s
    @expiration_date_start = params[:expiration_date_start].to_s
    @expiration_date_end = params[:expiration_date_end].to_s
    if @search.length > 0
      searchText = '%'+@search+'%'
      @subscriptions = Subscription.joins('INNER JOIN users AS u ON u.id=subscriptions.userid').where("CONCAT(u.first_name,' ',u.last_name) LIKE ?",searchText)
    else
      @subscriptions = Subscription    
    end
    if @status == "Active" || @status == "Pending"
      @subscriptions = @subscriptions.where("status=?",@status)
    end
    if @plan!=""
      
      @subscriptions = @subscriptions.where("plan=?",@plan)
    end
    if @expiration_date_start!=""
      @subscriptions = @subscriptions.where("date(expiration)>=?",@expiration_date_start)
    end
    if @expiration_date_end!=""
      @subscriptions = @subscriptions.where("date(expiration)<=?",@expiration_date_end)
    end
    @subscriptions = @subscriptions.order('created_at DESC').paginate(:page => params[:page], :per_page => 10)    
  end

  # GET /plans/1
  # GET /plans/1.json
  def show
    @lastInvoice = Invoice.where("subscr_id=?",@subscription.id).order('id DESC').take
    @form_action = 'update'
  end

  # GET /subscriptions/1/edit
  def edit
    @form_action = 'update'
  end

  # PATCH/PUT /plans/1
  # PATCH/PUT /plans/1.json
  def update
    expiration_date = params[:expiration_date]
    status = params[:status]
    plan = params[:plan]    
    if expiration_date!=nil
      @subscription.update_attributes(:expiration => expiration_date)
    end
    if (status == "Active" || status == "Pending")
      @subscription.update_attributes(:status => status)
    end
    if plan != ""
      @subscription.update_attributes(:plan => plan)
    end
    respond_to do |format|
      format.html { redirect_to @subscription, notice: 'Subscription was successfully updated.' }
    end
  end

  #added by sam
  def clear_invoice
    invoice_number = params[:invoice_number]
    invoice_obj = Invoice.where('invoice_number = ?', invoice_number).take
    if invoice_obj != nil
      if invoice_obj.active
        flash[:alert] = 'Invoice is already used'
        redirect_to(subscriptions_path) and return
      end
      invoice_obj.update_attributes(:active => 1,
                                    :transaction_date => Time.now.to_datetime.utc
                                    )
      subscr_id = invoice_obj.subscr_id
      subscription_obj = Subscription.find(subscr_id)
      last_expiration = DateTime.parse(subscription_obj.expiration.to_s)
      
      subscription_obj.update_attributes(:status => 'Active',
                                          :plan => invoice_obj.used_plan
                                        )
        flash[:notice] = 'Invoice successfully cleared'
        redirect_to(subscription_obj) and return
    end
  end
  
  #added by sam
  def set_expiration_date
    subscription_id = params[:subscription_id]
    expiration_date = params[:expiration_date]
    if subscription_id!=nil && expiration_date!=nil
      subscription_obj = Subscription.find(subscription_id)
      if subscription_obj != nil
        subscription_obj.update_attributes(:expiration => expiration_date)
      end
      flash[:notice] = 'Expiration date changed successfully'
      redirect_to(subscription_obj) and return
    else 
      flash[:alert] = 'Subscription id or expiration date is missing'
    end
    redirect_to(root_path) and return
  end
  
  #added by sam 
  def set_subscription_status
    subscription_id = params[:subscription_id]
    status = params[:status]
    if subscription_id!=nil && status!=nil && (status == "Active" || status == "Pending")
      subscription_obj = Subscription.find(subscription_id)
      if subscription_obj != nil
        subscription_obj.update_attributes(:status => status)
      end
      flash[:notice] = 'Subscription Status changed successfully'
      redirect_to(subscription_obj) and return
    else 
      flash[:alert] = 'Subscription id or expiration date is missing'
    end
    redirect_to(root_path) and return
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end
    
    def is_admin
      if current_user.role != 'administrator'
        flash[:alert] = 'You are not authorized to view this resource!'
        redirect_to(root_path)
      end
    end
    
end
