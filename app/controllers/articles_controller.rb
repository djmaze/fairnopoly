#
#
# == License:
# Fairnopoly - Fairnopoly is an open-source online marketplace.
# Copyright (C) 2013 Fairnopoly eG
#
# This file is part of Fairnopoly.
#
# Fairnopoly is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairnopoly is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairnopoly.  If not, see <http://www.gnu.org/licenses/>.
#
class ArticlesController < InheritedResources::Base
  # Inherited Resources
  respond_to :html
  actions :all # inherited methods

  # Authorization
  skip_before_filter :authenticate_user!, :only => [:show, :index, :autocomplete]
  skip_after_filter :verify_authorized_with_exceptions, only: [:autocomplete]

  # Layout Requirements
  before_filter :ensure_complete_profile , :only => [:new, :create]
  #before_filter :authorize_resource, :only => [:edit, :show]

  #search_cache
  before_filter :build_search_cache, :only => :index

  # Calculate value of active goods
  before_filter :check_value_of_goods, :only => [:new, :create]

  #Sunspot Autocomplete
  def autocomplete
    search = Sunspot.search(Article) do
      fulltext permitted_search_params[:keywords] do
        fields(:title)
      end
    end
    @titles = []
    search.hits.each do |hit|
      title = hit.stored(:title).first
      @titles.push(title)
    end
    render :json => @titles
  rescue Errno::ECONNREFUSED
    render :json => []
  end

  def show
    @article = Article.find params[:id]
    authorize resource

    if !resource.active? && policy(resource).activate?
      resource.calculate_fees_and_donations
    end
    show!
  rescue Pundit::NotAuthorizedError
    raise ActiveRecord::RecordNotFound # hide articles that can't be accessed to generate more friendly error messages
  end

  def new
    authorize build_resource
    ############### From Template ################
    if @applied_template = ArticleTemplate.template_request_by(current_user, permitted_new_params[:template_select])
      @article = @applied_template.article.amoeba_dup
      flash.now[:notice] = t('template_select.notices.applied', :name => @applied_template.name)
    elsif permitted_new_params[:edit_as_new]
      @old_article = current_user.articles.find(permitted_new_params[:edit_as_new])
      @article = Article.edit_as_new @old_article
    end
    new!
  end

  def edit
    authorize resource
    edit!
  end

  def create
    authorize build_resource
    create! do |success, failure|
      success.html { redirect_to resource }
      failure.html { save_images
                     render :new }
    end
  end

  def update # Still needs Refactoring
    if state_params_present?
      change_state!
    else
      authorize resource
      update! do |success, failure|
        success.html { redirect_to resource }
        failure.html { save_images
                       render :edit }
      end
    end

  end

  def destroy
    authorize resource
    if resource.preview?
      destroy! { user_path(current_user) }
    elsif resource.locked?
      resource.close_without_validation

      redirect_to user_path(current_user)
    end
  end

  ##### Private Helpers


  private

    def change_state!

      # For changing the state of an article
      # Refer to Article::State
      if permitted_state_params[:activate]
        authorize resource, :activate?
        if resource.activate
          flash[:notice] = I18n.t('article.notices.create_html').html_safe
          redirect_to resource
        else
          # The article became invalid so please try a new one
          redirect_to new_article_path(:edit_as_new => resource.id)
        end
      elsif permitted_state_params[:deactivate]
        authorize resource, :deactivate?
        resource.deactivate_without_validation
        flash[:notice] = I18n.t('article.notices.deactivated')
        redirect_to resource
      end
    end

    def state_params_present?
      permitted_state_params[:activate] || permitted_state_params[:deactivate]
    end


    def search_for query
      ######## Solr
        search = query.find_like_this permitted_search_params[:page]
        return search.results
      ########
      rescue Errno::ECONNREFUSED
        render_hero :action => "sunspot_failure"
        return policy_scope(Article).page permitted_search_params[:page]
    end

    def permitted_state_params
      params.permit :activate, :deactivate, :confirm_to_buy
    end
    def permitted_new_params
      params.permit :edit_as_new, template_select: [:article_template]
    end
    def permitted_search_params
      params.permit :page, :keywords
    end
    def permitted_queue_params
      params.permit :page, :queue
    end

    def check_value_of_goods
      if current_user.value_of_goods_cents > ( current_user.max_value_of_goods_cents + current_user.max_value_of_goods_cents_bonus )
        redirect_to user_path(current_user), alert: I18n.t('article.notices.max_limit')
      end
    end

    ############ Save Images ################

    def save_images
      #At least try to save the images -> not persisted in browser
      resource.images.each do |image|
        image.save
      end
    end

  ################## Inherited Resources
  protected

    def collection
      if params[:queue]
        @articles ||= Exhibit.all_from permitted_queue_params[:queue],permitted_queue_params[:page]
      else
        @articles ||= search_for @search_cache
      end
    end

    def begin_of_association_chain
      current_user
    end

    def build_search_cache
     @search_cache = Article.new(permitted_params[:article])
    end


end
