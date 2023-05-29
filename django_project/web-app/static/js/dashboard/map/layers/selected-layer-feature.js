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

        initialize: function (mapView) {
            this.mapView = mapView;
            const map = mapView.map;
            event.register(this, evt.FEATURE_HIGHLIGHTED, this.featureHighlighted);

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
                  'line-width': 2,
                }
            })
            map.addLayer({
                id: this.layerId + '-circle',
                type: 'circle',
                source: this.layerId,
                filter: ['==', '$type', 'Point'],
                paint: {
                  'circle-color': `rgb(255, 255, 0)`,
                  'circle-stroke-width': 1,
                }
            })
        },
        /** Highlight specific feature
         * @param feature, selected feature object
         */
        featureHighlighted: function (feature) {
            const geojson = {
              "type": "FeatureCollection",
              "features": []
            }
            if (feature) {
                geojson.features = [feature]
            }
            this.mapView.map.getSource(this.layerId).setData(geojson);
        },
    });
});