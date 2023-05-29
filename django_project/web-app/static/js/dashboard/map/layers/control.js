/**
 * This controls QGIS layers to be drawn to map
 * It draws element of html to select/unselect the layer
 */
define([
    'backbone',
    'jquery',
    'js/map/layers/main-layer',
    'js/map/layers/selected-layer-feature'
], function (
    Backbone, $, MainLayer, SelectedLayer) {
    return Backbone.View.extend({
        selectedLayer: null,
        layer: null,

        initialize: function (mapView) {
            const that = this;
            this.$el = $('#layers')
            this.style = '';
            this.mapView = mapView;
            this.selectedLayer = new SelectedLayer(mapView);
            event.register(this, evt.LAYER_STYLE_CHANGE, this.changeStyle);

            $('#layer-list-toggle').click(function () {
                $('#left-top').toggleClass('show');
            })

            // Create legend toggler
            $.each(QGISLayers, function (layerName, values) {
                const id = layerName.replaceAll(' ', '-');
                // restructure the html
                const html = templates.LAYER_SELECTION_ROW({
                    layername: layerName,
                    id: id,
                    legendURL: ''
                });
                that.$el.append(html);
            });
            this.changeStyle('')

            // Create layers
            this.layer = new MainLayer(mapView);

            // event when checkbox clicked
            this.$el.find('.fa-check-square, .fa-square-o').click(function () {
                const $row = $(this).closest('.layer-row')
                $row.toggleClass('active');
                that.activeClassesChanged();
            })
            this.activeClassesChanged();
        },
        /** Update legend
         */
        updateLegends: function(style) {
            for (const [layerName, value] of Object.entries(QGISLayers)) {
                let html = value.legends.map(url=>{
                    return `<img src="${url}">`
                })
                const id = layerName.replaceAll(' ', '-');
                const $legend = $(`#${id} img`);
                $legend.replaceWith(`<div>${html.join('')}</div>`);
            }
        },
        /** Get Legend url
         */
        changeStyle: function (style) {
            this.updateLegends(style)

            // if it is null
            // style does not need to be changed
            if (style === null) {
                return
            }
            if (this.style === style) {
                return
            }
            this.style = style;
        },

        /**
         * Return layer name that active
         */
        getActiveLayersName: function () {
            let names = [];
            $('#layers .active').each(function () {
                names.push($(this).data('layername'))
            })
            return names
        },

        /**
         * Activate classes changed
         */
        activeClassesChanged: function () {
            const qgisLayers = this.getActiveLayersName();

            // For active class for graph
            let classes = [];
            qgisLayers.forEach(function (layerName) {
                classes = classes.concat(QGISLayers[layerName].classes);
            });
            event.trigger(evt.CLASSES_LIST_CHANGE, classes);
            this.layer.classes = classes
            this.layer.filterLayers()
        },
    });
});