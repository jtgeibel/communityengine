class EventsController < BaseController

  require 'htmlentities'
  caches_page :ical
  cache_sweeper :event_sweeper, :only => [:create, :update, :destroy]
 
  #These two methods make it easy to use helpers in the controller.
  #This could be put in application_controller.rb if we want to use
  #helpers in many controllers
  def help
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::SanitizeHelper
    extend ActionView::Helpers::SanitizeHelper::ClassMethods
  end

  uses_tiny_mce(:only => [:new, :edit, :create, :update, :clone ]) do
    AppConfig.default_mce_options
  end
  
  uses_tiny_mce(:only => [:show]) do
    AppConfig.simple_mce_options
  end

  before_filter :admin_required, :except => [:index, :show, :ical]

  def ical
    @calendar = RiCal.Calendar
    @calendar.add_x_property 'X-WR-CALNAME', AppConfig.community_name
    @calendar.add_x_property 'X-WR-CALDESC', "#{AppConfig.community_name} #{:events.l}"
    Event.find(:all).each do |ce_event|
      rical_event = RiCal.Event do |event|
        event.dtstart = ce_event.start_time
        event.dtend = ce_event.end_time
        event.summary = ce_event.name + (ce_event.neighborhood.blank? ? '' : " (#{ce_event.neighborhood})")
        coder = HTMLEntities.new
        event.description = (ce_event.description.blank? ? '' : coder.decode(help.strip_tags(ce_event.description).to_s) + "\n\n") + event_url(ce_event)
        event.location = ce_event.location unless ce_event.location.blank?
      end
      @calendar.add_subcomponent rical_event
    end
    headers['Content-Type'] = "text/calendar; charset=UTF-8"
    render :text => @calendar.export_to, :layout => false
  end

  def show
    @is_admin_user = (current_user && current_user.admin?)
    @event = Event.find(params[:id])
    @comments = @event.comments.find(:all, :limit => 20, :order => 'created_at DESC', :include => :user)
  end

  def index
    @is_admin_user = (current_user && current_user.admin?)
    @events = Event.upcoming.find(:all, :page => {:current => params[:page]})
  end

  def past
    @is_admin_user = (current_user && current_user.admin?)
    @events = Event.past.find(:all, :page => {:current => params[:page]})
    render :template => 'events/index'
  end

  def new
    @event = Event.new(params[:event])
    @neighborhoods = setup_neighborhood_choices_for(current_user)
    @neighborhood_id, @county_id = setup_location_for(current_user)
  end
  
  def edit
    @event = Event.find(params[:id])
    @neighborhoods = setup_neighborhood_choices_for(@event)
    @neighborhood_id, @county_id = setup_location_for(@event)
  end
    
  def create
    @event = Event.new(params[:event])
    @event.user = current_user
    if params[:neighborhood_id]
      @event.neighborhood = Neighborhood.find(params[:neighborhood_id])
    else
      @event.neighborhood = nil
    end
    respond_to do |format|
      if @event.save
        flash[:notice] = :event_was_successfully_created.l
        
        format.html { redirect_to event_path(@event) }
      else
        format.html { 
          @neighborhoods = setup_neighborhood_choices_for(@event)
          if params[:neighborhood_id]
            @neighborhood_id = params[:neighborhood_id].to_i
            @county_id = params[:county_id].to_i
          end
          render :action => "new"
        }
      end
    end    
  end

  def update
    @event = Event.find(params[:id])
    if params[:neighborhood_id]
      @event.neighborhood = Neighborhood.find(params[:neighborhood_id])
    else
      @event.neighborhood = nil
    end
        
    respond_to do |format|
      if @event.update_attributes(params[:event])
        format.html { redirect_to event_path(@event) }
      else
        format.html { 
          @neighborhoods = setup_neighborhood_choices_for(@event)
          if params[:neighborhood_id]
            @neighborhood_id = params[:neighborhood_id].to_i
            @county_id = params[:county_id].to_i
          end
          render :action => "edit"
        }
      end
    end
  end
  
  def destroy
    @event = Event.find(params[:id])
    @event.destroy
    
    respond_to do |format|
      format.html { redirect_to :back }
    end
  end

  def clone
    @event = Event.find(params[:id]).clone
    @metro_areas, @states = setup_metro_area_choices_for(@event)
    @metro_area_id, @state_id, @country_id = setup_location_for(@event)
    render :template => 'events/new'
  end

  protected

  def setup_neighborhood_choices_for(object)
    neighborhoods = []
    if object.neighborhood
      if object.is_a? Event
        neighborhoods = object.neighborhood.county.neighborhoods.all(:order=>"name")  
      elsif object.is_a? User
        neighborhoods = object.county.neighborhoods.all(:order => "name")
      end
    end
    return neighborhoods
  end

  def setup_location_for(object)
    neighborhood_id = county_id = nil
    if object.neighborhood
      neighborhood_id = object.neighborhood_id
      if object.is_a? Event
        county_id = object.neighborhood.county_id
      elsif object.is_a? User
        county_id = object.county_id
      end
    end
    return neighborhood_id, county_id
  end

end
