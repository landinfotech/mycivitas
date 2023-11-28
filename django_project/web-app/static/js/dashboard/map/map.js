/**
 * This file contains leaflet map controller
 * Put just function of map in here  
 */

const sourceLayerID = 'MyCivitas';

define([
    'backbone',
    'jquery',
    'js/map/layers/control'
], function (
    Backbone, $, Layers) {
    return Backbone.View.extend({
        loadStyle: function () {
            return RequestFn.promiseGet(styleUrl)
        },
        /**
         * Initialization
         */
        initialize: async function (initFinishedFn) {
            const style = await this.loadStyle();

            style.sources[sourceLayerID].tiles = [domain + 'community-layer/{z}/{x}/{y}/']

            // Hide all filters first
            // Hover layer
            for (const [layerId, layer] of Object.entries(style.layers)) {
                if (layer.source === sourceLayerID) {
                    layer.filter = layer.filter.concat(
                        [["==", "community_id", 'nothing']]
                    )
                }
            }

            this.map = new maplibregl.Map({
                container: 'map',
                style: style,
                center: [-99.12721296328681, 57.37234033920234],
                zoom: 4,
                workercount:12,
                refreshExpiredTiles: true,
            });

            this.map.once("load", () => {
              initFinishedFn()
              this.listener();

              new Layers(this);
            })

            this.map.on('click', function (e) {
                event.trigger(evt.MAP_CLICKED, e.lngLat);
            });
        },
        /** Init listener for map
         */
        listener: function () {
            event.register(this, evt.MAP_PAN, this.panTo);
            event.register(this, evt.MAP_FLY, this.flyTo);
            event.register(this, evt.MAP_ADD_LAYER, this.addLayer);
            event.register(this, evt.MAP_REMOVE_LAYER, this.removeLayer);
        },
        /**
         * Pan map to lat lng
         * @param lat
         * @param lng
         * @param zoom
         */
        panTo: function (lat, lng, zoom) {
            if (zoom) {
                this.map.flyTo([lat, lng], zoom, {
                    duration: 0.5
                });
            } else {
                this.map.panTo(new L.LatLng(lat, lng));
            }
        },
        /**
         * Pan map to lat lng
         * @param bounds
         */
        flyTo: function (bounds) {
            this.map.fitBounds(bounds, {
                animate: false,
                padding: {top: 100, bottom: 100, left: 100, right: 100}
            });
        },

        /**
         * Return if layer exist or not
         * @param {String} id of layer
         */
        hasLayer : function (id){
            return typeof this.map.getLayer(id) !== 'undefined'
        },

        /**
         * Return if source exist or not
         * @param {String} id of layer
         * @param {dict} options of layer
         */
        addLayer : function (id, options, before=null) {
            this.removeLayer(id)
            this.map.addLayer(options, before);
        },

        /**
         * Return if layer exist or not
         * @param {String} id of layer
         */
        removeLayer : function (id) {
          if (this.hasLayer(id)) {
              this.map.removeLayer(id)
          }
        },

        /**
         * Show layer
         * @param {String} id of layer
         */
        showLayer : function (id) {
          if (this.hasLayer(id)) {
            this.map.setLayoutProperty(id, 'visibility', 'visible');
          }
        },

        /**
         * Hide layer
         * @param {String} id of layer
         */
        hideLayer : function (id) {
          if (this.hasLayer(id)) {
            this.map.setLayoutProperty(id, 'visibility', 'none');
          }
        },

        /**
         * Return if source exist or not
         * @param {String} id of layer
         */
        hasSource : function (id) {
            return typeof this.map.getSource(id) !== 'undefined'
        },

        /**
         * Return if source exist or not
         * @param {String} id of layer
         * @param {dict} options of layer
         */
        addSource : function (id, options) {
            this.removeSource(id)
            this.map.addSource(id, options);
        },

        /**
         * Return if source exist or not
         * @param {String} id of layer
         */
        removeSource : function (id){
            if (this.hasSource(id)) {
                this.map.removeSource(id);
            }
        }

    });
});