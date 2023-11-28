/**
 * Handling specific layer of QGIS
 * It controls how to call the wms layer and also the highlight layer  
 */
define([
    'backbone',
    'jquery',
    'js/map/layers/control'
], function (
    Backbone, $, Layers) {
    return Backbone.View.extend({
        loadStyle: function (style) {
            return RequestFn.promiseGet(style)
        },
        defaultFilter: {},
        isRemove: false,
        initialize: function (mapView) {
            this.mapView = mapView;
            const map = mapView.map
            this.map = map
            this.layerIds = []
            event.register(this, evt.COMMUNITY_CHANGE, this.communityChanged)
            event.register(this, evt.HEATMAP_CHANGED, this.heatmap_changed);
            this.selectedId = null;
            this.currentID = null;
            this.map_interactions()
        },

        map_interactions: function(){
            // Hover layer
            for (const [layerId, layer] of Object.entries(map.style._layers)) {

                map.on('contextmenu', layerId, (e) => {
                    event.trigger(evt.FEATURE_REMOVE_HIGHLIGHTED, layerId);
                });
                
                if(layer.source === 'highlight'){
                    var popup = new maplibregl.Popup({
                        offset: [0, -7],
                        closeButton: false,
                        closeOnClick: false
                    });
                    
                    map.on("mousemove", layerId, (e) => {
                        popup
                        .setLngLat(e.lngLat)
                        .setHTML('Right Click to deselect' )
                        .addTo(map);
                    });
                    map.on("mouseleave", layerId, () => {
                        popup.remove();
                    });
                }
                if (layer.source === sourceLayerID) {
                    if(this.map.getLayer(layerId)){
                        this.layerIds.push(layerId)
                        this.defaultFilter[layerId] = JSON.parse(JSON.stringify(layer.filter))

                        map.on("mousemove", layerId, () => {
                            map.getCanvas().style.cursor = "pointer";
                        });

                        map.on("mouseleave", layerId, () => {
                            map.getCanvas().style.cursor = "grab";
                        });

                        map.on("click", layerId, (e) => {
                            const features = map.queryRenderedFeatures(e.point);
                            var featureArr = []
                            features.forEach(element => {
                                var isIndex = featureArr.findIndex(x => x.id == element.properties.id)
                                if(isIndex == -1){
                                    featureArr.push({"id": element.properties.id, "layer": layerId})
                                }
                            });
                            console.log("feature clicked", featureArr)
                            this.featureClicked(featureArr)
                        });
                    }

                }
            }
        },

        load_style : async function(_style){

            let all_layers = this.map.getStyle().layers

            for(var i = 0; i < all_layers.length; i++){
                if(all_layers[i]["source"] == sourceLayerID){
                    map.removeLayer(all_layers[i]["id"]);
                }
            }
            const _source = await this.loadStyle(_style)

            let features_arr = []

            _source.layers.map(item => {
                if(item.source == sourceLayerID){
                    features_arr.push(item)
                }
            })

            const new_source = {
                'type': 'FeatureCollection',
                'features': features_arr
            }

            for (const feature of new_source.features){
                if(!this.map.getLayer(feature["id"])){
                    this.map.addLayer(feature)
                }
                else{
                    this.map.setLayoutProperty(feature["id"], 'visibility', 'visible')
                }
            }

            this.map_interactions();
            this.filterLayers();
            
        },

        /***
        * When style changes
        * @param style
        */

        heatmap_changed: function(ID){
            event.trigger(evt.FEATURE_REMOVE_HIGHLIGHTED, "");

            switch(ID){
                case 'consequence-of-failure':
                    this.load_style(cofStyleUrl);
                    break;
                case 'probability-of-failure':
                    this.load_style(pofStyleUrl);
                    break;
                case 'risk':
                    this.load_style(riskStyleUrl)
                    break;
                case 'widget-ticket':
                    this.load_style(styleUrl)
                    break;
                default:
                    break;
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
        featureClicked: async function (featuresArr) {
            try {
                var finalArr = []
                for(var i = 0; i < featuresArr.length; i++){
                    var id = featuresArr[i]["id"]
                    this.detailLoading = true
                    event.trigger(evt.FEATURE_LIST_FETHCING);
                    const feature = await RequestFn.promiseGet(
                        urls.feature_data.replaceAll('0', id)
                    )
                    finalArr.push(feature)
                }
            console.log("finalArr", finalArr)
            event.trigger(evt.FEATURE_LIST_FETHCED, finalArr);
            } catch (error) {
                
            }
            // event.trigger(evt.LAYER_SELECTED, layer);
            // this.selectedId = id
            // try {
            //     // Trigger event when feature list starting fetching
            //     this.detailLoading = true
            //     event.trigger(evt.FEATURE_LIST_FETHCING);
            //     const feature = await RequestFn.promiseGet(
            //       urls.feature_data.replaceAll('0', id)
            //     )
            //     if(this.selectedId === id) {
            //         this.currentID = id
            //         console.log("start to trigger", feature)
            //         event.trigger(evt.FEATURE_LIST_FETHCED, [feature]);
            //     }
            // } catch (e) {
            // }
        },
        /**
         * Filter layers
         */
        filterLayers: function () {
            const classes = this.classes
            this.layerIds.map(layerId => {
                let filter = this.defaultFilter[layerId]
                if (classes) {
                    for(var i = 0; i < filter.length; i++){
                        if(filter[i].includes("asset_identifier")){
                            filter.splice(i, 1)
                        }
                    }
                    
                    filter = filter.concat(
                        [["in", "asset_identifier", ...classes]]
                    )
                }
                if (this.community_id) {
                    for(var i = 0; i < filter.length; i++){
                        if(filter[i].includes("community_id")){
                            filter.splice(i, 1)
                        }
                    }
                    filter = filter.concat(
                        [["==", "community_id", this.community_id]]
                    )
                }

                if(this.map.getLayer(layerId)){
                    // add layer to filter list if exist
                    this.map.setFilter(
                        layerId,
                        filter
                    )
                }
                else{
                    // remove layer from filter list
                    const index = this.layerIds.indexOf(layerId)
                    this.layerIds.splice(index, 1)
                }

            })
        }
    });
});