class NeighborhoodsController < BaseController
  def neighborhood_update
    county = County.find(params[:county_id]) unless params[:county_id].blank?
    neighborhoods  = county ? county.neighborhoods.sort_by{|s| s.name} : []

    respond_to do |format|
      format.js {
        render :partial => 'shared/location_chooser', :locals => {
          :neighborhoods => neighborhoods, 
          :selected_county => params[:county_id].to_i, 
          :selected_neighborhood => nil }
      }
    end
  end
end
