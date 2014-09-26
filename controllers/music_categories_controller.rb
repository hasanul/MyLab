class MusicCategoriesController < ApplicationController
  before_action :set_music_category, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!
  before_filter :is_admin
  protect_from_forgery except: :save_ordering
  layout 'admin_layouts'

  # GET /music_categories
  # GET /music_categories.json
  def index
    @search = params[:search].to_s
    if @search.length > 0
      searchText = '%'+@search+'%'
      @music_categories = MusicCategory.where("name LIKE ?",searchText).order('ordering ASC').paginate(:page => params[:page], :per_page => 10)
    else
      @music_categories = MusicCategory.order('ordering ASC').paginate(:page => params[:page], :per_page => 10)    
    end
  end

  # GET /music_categories/1
  # GET /music_categories/1.json
  def show
  end

  # GET /music_categories/new
  def new
    @music_category = MusicCategory.new
    @form_action = 'create'
  end

  # GET /music_categories/1/edit
  def edit
    @form_action = 'update'
  end

  # POST /music_categories
  # POST /music_categories.json
  def create
    @music_category = MusicCategory.new(music_category_params)

    respond_to do |format|
      if @music_category.save
        format.html { redirect_to @music_category, notice: 'Music category was successfully created.' }
        format.json { render action: 'show', status: :created, location: @music_category }
      else
        format.html { render action: 'new' }
        format.json { render json: @music_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /music_categories/1
  # PATCH/PUT /music_categories/1.json
  def update
    respond_to do |format|
      if @music_category.update(music_category_params)
        format.html { redirect_to @music_category, notice: 'Music category was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @music_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /music_categories/1
  # DELETE /music_categories/1.json
  def destroy
    @music_category.destroy
    respond_to do |format|
      format.html { redirect_to music_categories_url, notice: 'Music category was successfully deleted.' }
      format.json { head :no_content }
    end
  end
  
  def save_ordering
    orderingData = params[:ordering]

    if orderingData!=nil && orderingData.length > 0
      orderingData.each do |orderItem|
        musicCatRow = MusicCategory.where("id = ?",orderItem[0]).take
        if musicCatRow!=nil && !musicCatRow.ordering.eql?(orderItem[1])
          musicCatRow.update(:ordering=>orderItem[1])
        end
      end
      allMusicCategories = MusicCategory.all().order('ordering ASC');
      if !allMusicCategories.nil?
        ordering = 1
        allMusicCategories.each do |item|
          item.update(:ordering=>ordering)
          ordering = ordering+1          
        end
      end 
      flash[:notice] = "Ordering was successfully saved."
      redirect_to(music_categories_path) and return
    else
      redirect_to('/') and return
    end
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_music_category
      @music_category = MusicCategory.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def music_category_params
      params.require(:music_category).permit(:name, :desc, :show_at_home_page)
    end
    
    def is_admin
      if current_user.role != 'administrator'
        flash[:alert] = 'You are not authorized to view this resource!'
        redirect_to(root_path)
      end
    end
end
