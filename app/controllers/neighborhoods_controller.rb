class NeighborhoodsController < BaseController
#  before_filter :login_required
#  before_filter :admin_required
  def neighborhood_update
    return unless request.xhr?
    
    county = County.find(params[:county_id]) unless params[:county_id].blank?
    neighborhoods  = county ? county.neighborhoods.sort_by{|s| s.name} : []

    render :partial => 'shared/location_chooser', :locals => {
      :neighborhoods => neighborhoods, 
      :selected_county => params[:county_id].to_i, 
      :selected_neighborhood => nil }
  end
end