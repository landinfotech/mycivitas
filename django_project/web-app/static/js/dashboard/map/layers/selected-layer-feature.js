/**
 * Handling features that are selected
 * It controls how to to highlight the feature
 * It has selectedFeatures and selectedFeature
 */
define([
    'backbone',
    'jquery'
], function (
    Backbone, $) {
    return Backbone.View.extend({
        layerId: 'highlight',
        selectedFeatures: [],
        selectedLayers: [],
        currentFeature: [],

        initialize: function (mapView) {
            this.mapView = mapView;
            const map = mapView.map;
            event.register(this, evt.FEATURE_HIGHLIGHTED, this.featureHighlighted);
            event.register(this, evt.LAYER_SELECTED, this.layerSelected);
            event.register(this, evt.FEATURE_REMOVE_HIGHLIGHTED, this.featureRemoveHighlighted);
            event.register(this, evt.HEATMAP_CHANGED, this.heatmap_changed);
            this.layerSelectedID = ""
            this._style = "widget-ticket"
            
            // create layer
            // add community layer
            map.addSource(this.layerId, {
                'type': 'geojson',
                'data': {
                    type: 'FeatureCollection',
                    features: []
                }
            })
            
            map.addLayer({
                id: this.layerId + '-polygon',
                type: 'fill',
                source: this.layerId,
                filter: ['==', '$type', 'Polygon'],
                paint: {
                'fill-color': `rgb(255, 255, 0)`,
                'fill-outline-color': `rgb(0, 0, 0)`,
                }
            })
            
            map.addLayer({
                id: this.layerId + '-line',
                type: 'line',
                source: this.layerId,
                filter: ['==', '$type', 'LineString'],
                paint: {
                'line-color': `rgb(255, 255, 0)`,
                'line-width': 4,
                }
            })
            
            map.addLayer({
                id: this.layerId + '-circle',
                type: 'circle',
                source: this.layerId,
                filter: ['==', '$type', 'Point'],
                paint: {
                'circle-color': `rgb(255, 255, 0)`,
                'circle-stroke-width': 3,
                }
            })

            map.addLayer({
                'id': this.layerId + '-polygon-outline',
                'type': 'line',
                'source': this.layerId ,
                filter: ['==', '$type', 'Polygon'],
                'layout': {},
                'paint': {
                'line-color': '#000',
                'line-width': 2,
                }
            });
            
            
        },
        /** Highlight specific feature
         * @param feature, selected feature object
         */

        featureRemoveHighlighted: function (feature){
            $('.tab-content').remove()
            $('#features-detail').find('.content-widget').html(`<div class="notification">Please click somewhere on the map. </div>`);
            var polygon_layer = this.mapView.map.getLayer(this.layerId + '-polygon')
            var polygon_outline_layer = this.mapView.map.getLayer(this.layerId + '-polygon-outline')
            var line_layer = this.mapView.map.getLayer(this.layerId + '-line')
            var circle_layer = this.mapView.map.getLayer(this.layerId + '-circle')

            if(typeof line_layer !== "undefined"){
                this.mapView.map.setLayoutProperty(this.layerId + '-line', 'visibility', 'none')
            }
            if(typeof polygon_layer !== "undefined"){
                this.mapView.map.setLayoutProperty(this.layerId + '-polygon', 'visibility', 'none')
            }
            if(typeof polygon_outline_layer !== "undefined"){
                this.mapView.map.setLayoutProperty(this.layerId + '-polygon-outline', 'visibility', 'none')
            }
            if(typeof circle_layer !== "undefined"){
                this.mapView.map.setLayoutProperty(this.layerId + '-circle', 'visibility', 'none')
            }
        },

        featureHighlighted: function (feature) {
            if(feature){
                var polygon_layer= this.mapView.map.getLayer(this.layerId + '-polygon')
                var polygon_outline_layer = this.mapView.map.getLayer(this.layerId + '-polygon-outline')
                var line_layer = this.mapView.map.getLayer(this.layerId + '-line')
                var circle_layer = this.mapView.map.getLayer(this.layerId + '-circle')

                const geojson = {
                "type": "FeatureCollection",
                "features": []
                }
                if (feature) {
                    geojson.features = [feature]
                }

                this.mapView.map.getSource(this.layerId).setData(geojson);

                if(this._style == "consequence-of-failure" || this._style == "probability-of-failure" || this._style == "risk" ){
                    
                    if(typeof line_layer !== "undefined"){
                        this.mapView.map.setLayoutProperty(this.layerId + '-line', 'visibility', 'visible')
                        this.mapView.map.moveLayer(this.layerId + '-line', this.layerSelectedID)
                    }
                    if(typeof polygon_layer !== "undefined"){
                        this.mapView.map.setLayoutProperty(this.layerId + '-polygon', 'visibility', 'visible')
                        this.mapView.map.moveLayer(this.layerId + '-polygon' , this.layerSelectedID)
                    }
                    if(typeof polygon_outline_layer !== "undefined"){
                        this.mapView.map.setLayoutProperty(this.layerId + '-polygon-outline', 'visibility', 'visible')
                        this.mapView.map.moveLayer(this.layerId + '-polygon-outline', this.layerSelectedID)
                    }
                    if(typeof circle_layer !== "undefined"){
                        this.mapView.map.setLayoutProperty(this.layerId + '-circle', 'visibility', 'visible')
                        this.mapView.map.moveLayer(this.layerId + '-circle', this.layerSelectedID)
                    }
                }
                else{
                    if(typeof line_layer !== "undefined"){
                        this.mapView.map.setLayoutProperty(this.layerId + '-line', 'visibility', 'visible')
                        this.mapView.map.moveLayer(this.layerId + '-line')
                    }
                    if(typeof polygon_layer !== "undefined"){
                        this.mapView.map.setLayoutProperty(this.layerId + '-polygon', 'visibility', 'visible')
                        this.mapView.map.moveLayer(this.layerId + '-polygon')
                    }
                    if(typeof polygon_outline_layer !== "undefined"){
                        this.mapView.map.setLayoutProperty(this.layerId + '-polygon-outline', 'visibility', 'visible')
                        this.mapView.map.moveLayer(this.layerId + '-polygon-outline')
                    }
                    if(typeof circle_layer !== "undefined"){
                        this.mapView.map.setLayoutProperty(this.layerId + '-circle', 'visibility', 'visible')
                        this.mapView.map.moveLayer(this.layerId + '-circle')
                    }
                }
            }
        },
        layerSelected: function(layer){
            this.layerSelectedID = layer
        },
        heatmap_changed: function(ID){
            this._style = ID;
            var polygon_layer = this.mapView.map.getLayer(this.layerId + '-polygon')
            var line_layer = this.mapView.map.getLayer(this.layerId + '-line')
            var circle_layer = this.mapView.map.getLayer(this.layerId + '-circle')

            switch(ID){
                case 'consequence-of-failure':
                case 'probability-of-failure':
                case 'risk':

                    if(typeof line_layer !== "undefined"){
                        this.mapView.map.setPaintProperty(
                            this.layerId + '-line', 'line-width', 4
                        );
                        this.mapView.map.setPaintProperty(
                            this.layerId + '-line', 'line-color', `rgb(0, 0, 0)`
                        );
                    }

                    if(typeof circle_layer !== "undefined"){
                        this.mapView.map.setPaintProperty(
                            this.layerId + '-circle', 'circle-stroke-width', 2
                        );
                        this.mapView.map.setPaintProperty(
                            this.layerId + '-circle', 'circle-color', `rgb(0, 0, 0)`
                        );
                    }

                    if(typeof polygon_layer !== "undefined"){
                        this.mapView.map.setPaintProperty(
                            this.layerId + '-polygon-outline', 'line-width', 4
                        );
                    }
                    break;
                case 'widget-ticket':
                    if(typeof line_layer !== "undefined"){
                        this.mapView.map.setPaintProperty(
                            this.layerId + '-line', 'line-width', 4
                        );
                        this.mapView.map.setPaintProperty(
                            this.layerId + '-line', 'line-color', `rgb(255, 255, 0)`
                        );
                        this.mapView.map.moveLayer(this.layerId + '-line')
                    }

                    if(typeof circle_layer !== "undefined"){
                        this.mapView.map.setPaintProperty(
                            this.layerId + '-circle', 'circle-stroke-width', 2
                        );
                        this.mapView.map.setPaintProperty(
                            this.layerId + '-circle', 'circle-color', `rgb(255, 255, 0)`
                        );
                        this.mapView.map.moveLayer(this.layerId + '-cicrcle')
                    }

                    if(typeof polygon_layer !== "undefined"){
                        this.mapView.map.setPaintProperty(
                            this.layerId + '-polygon-outline', 'line-width', 2
                        );
                        this.mapView.map.moveLayer(this.layerId + '-polygon')
                    }
                    break;
                default:
                    break;
            }
        }
    });
});