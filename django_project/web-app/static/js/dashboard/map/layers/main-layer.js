/**
 * Handling specific layer of QGIS
 * It controls how to call the wms layer and also the highlight layer  
 */
define([
    'backbone',
    'jquery'
], function (
    Backbone, $) {
    return Backbone.View.extend({
        defaultFilter: {},
        initialize: function (mapView) {
            this.mapView = mapView;
            const map = mapView.map
            this.map = map
            this.layerIds = []
            event.register(this, evt.COMMUNITY_CHANGE, this.communityChanged)

            this.selectedId = null

            // Hover layer
            for (const [layerId, layer] of Object.entries(map.style._layers)) {
                if (layer.source === sourceLayerID) {
                    this.layerIds.push(layerId)
                    this.defaultFilter[layerId] = JSON.parse(JSON.stringify(layer.filter))
                    this.defaultFilter[layerId].pop()

                    map.on("mousemove", layerId, () => {
                        if(layer.type == "line"){
                            if(layer.id.includes("-extra1")){
                                map.getCanvas().style.cursor = "pointer";
                            }
                        }
                        else if(layer.type != "line"){
                            map.getCanvas().style.cursor = "pointer";
                        }
                    });

                    map.on("mouseleave", layerId, () => {
                        map.getCanvas().style.cursor = "grab";
                    });

                    map.on("click", layerId, (e) => {
                        this.featureClicked(e.features[0].properties.id)
                    });

                }
            }

        },
        /***
        * When community change
        * @param community
        */
        communityChanged: function (community) {
            let community_id = 0
            if (community) {
                this.community_id = community.get('id')
                community_id = this.community_id
                this.map.getSource(sourceLayerID).setTiles([
                  domain + 'community-layer/{z}/{x}/{y}/?community_ids=' + community_id
                ])
            }
            this.filterLayers()
        },
        /***
        * Feature clicked
        * @param id
        */
        featureClicked: async function (id) {
            this.selectedId =id
            try {

                // Trigger event when feature list starting fetching
                this.detailLoading = true
                event.trigger(evt.FEATURE_LIST_FETHCING);
                const feature = await RequestFn.promiseGet(
                  urls.feature_data.replaceAll('0', id)
                )
                if(this.selectedId === id) {
                    event.trigger(evt.FEATURE_LIST_FETHCED, [feature]);
                }
            } catch (e) {
            }
        },
        /**
         * Filter layers
         */
        filterLayers: function () {
            const classes = this.classes
            this.layerIds.map(layerId => {
                let filter = this.defaultFilter[layerId]

                if (classes) {
                    filter = filter.concat(
                        [["in", "asset_identifier", ...classes]]
                    )
                }
                if (this.community_id) {
                    filter = filter.concat(
                        [["==", "community_id", this.community_id]]
                    )
                }
                this.map.setFilter(
                  layerId,
                  filter
                )
            })
        }
    });
});