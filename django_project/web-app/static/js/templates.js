// this is identifier of all templates
const templates = {
    CREATE_TICKET: '#_create-ticket',
    COMING_SOON: '#_coming_soon',
    LAYER_SELECTION_ROW: '#_layer-selection-row',
    LAYER_SELECTION_DROPDOWN_ROW: '#_layer-selection-row-dropdown',
    LAYER_SELECTION_ASSET_SUB_ROW: '#_layer-selection-row-asset-sub',
    HEATMAP_SELECTION_ROW: '#_layer-selection-row-heatmap',
    SYSTEM_SELECTION_ROW: '#_layer-selection-row-system-name',
    LOADING: '#_loading',
    NODATAFOUND: '#_no_data_found',
    PLEASE_CLICK_MAP: '#_please_click_map',
    PLEASE_ADD_FEATURE: '#_please_add_feature',
    ROW_PROPERTY: '#_row_property',
    FEATURE_INFO: '#_feature_info',
    WIDGET_CONTENT: '#_widget-content',
    WIDGET_BUTTON: '#_widget-button',
    NO_ACCESS: '#_no_access',

    // Feature Detail
    FEATURE_DETAIL_TAB: '#_feature_detail_tab',
    FEATURE_DETAIL_TAB_PANE: '#_feature_detail_tab_pane',

    // Ticket Detail
    TICKET_DETAIL: '#_ticket-detail',
    TICKET_FEATURE: '#_ticket-feature',
    
    ASSET_MANAGEMENT_WIDGET: '#_asset-management-widget',
}
define([
    'backbone'], function (Backbone) {
    return Backbone.View.extend({
        initialize: function () {
            $.each(templates, function (key, value) {
                templates[key] = _.template($(value).html())
            });
        }
    });
});