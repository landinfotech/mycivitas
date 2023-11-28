/**
 * Handler of dispatcher event
 */
const evt = {
    COMMUNITY_CHANGE: 'community:change', // when community selected/changed
    COMMUNITY_GEOJSON_CHANGE: 'community:geojson:change', // when community geojson fetched

    MAP_PAN: 'map:pan', // pan the map
    MAP_FLY: 'map:fly', // fly the map
    FEATURE_PAN: 'feature:pan',
    MAP_ADD_LAYER: 'map:layer:add', // add layer to map
    MAP_REMOVE_LAYER: 'map:layer:remove', // remove layer from map
    MAP_CLICKED: 'map:click', // draw click,

    HEATMAP_CHANGED: 'style:changed',

    CLASSES_LIST_CHANGE: 'classes-list:change', // classes list changes
    LAYER_STYLE_CHANGE: 'layer:change-style', // change layer style

    NOTIFICATION_ADD: 'notification:add', // add a notification
    SYSTEM_CHANGE: 'system:change', // when system change
    WIDGETS_HIDE: 'widget:all:hide', // hide all widget

    FEATURE_LIST_FETHCING: 'features:fetching', // When data is fetching
    FEATURE_LIST_FETHCED: 'features:fetched', // When data has been fetched
    FEATURE_HIGHLIGHTED: 'features:remove_highlighted', // When feature selected
    LAYER_SELECTED: 'features:layer_highlighted', // When feature selected
    FEATURE_REMOVE_HIGHLIGHTED: 'features:highlighted', // When feature selected
    FEATURE_SELECT_HIGHLIGHTED: 'features:select_highlighted', // When feature selected
    FEATURE_REMOVED_FROM_BASKET: 'features:remove-from-basket', // Feature removed from basket

    TICKET_BASKET_ADD_FEATURE: 'ticket-list:add-feature', // Add feature to ticket list
    TICKET_BASKET_REMOVE_FEATURE: 'ticket-list:remove-feature', // Remove feature to ticket list
    TICKET_BASKET_CHECK: 'ticket-list:feature-check', // Check feature in basket or not
}
define([
    'backbone'], function (Backbone) {
    return Backbone.View.extend({

        initialize: function () {
            this.dispatcher = _.extend({}, Backbone.Events);
        },
        /** Register event with specific name for an objecy
         * @param obj
         * @param name, name of event that will be used
         * @param func, function that will be called for the event
         */
        register: function (obj, name, func) {
            obj.listenTo(this.dispatcher, name, func);
        },
        /** Trigger event with specific name
         * @param name, name of event that will be used
         * @param args, any parameters that will be passed to function
         */
        trigger: function (name, ...args) {
            this.dispatcher.trigger(name, ...args)
        }
    });
});