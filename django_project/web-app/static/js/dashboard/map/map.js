/**
 * This file contains leaflet map controller
 * Put just function of map in here  
 */

const sourceLayerID = 'MyCivitas';
var canvas;
var start;
var current;
var box;
var isCreateTicket;
var _map;
var featuresArr

function _containsObject(arr, feature_id){
    return arr.some(el => el.id === feature_id);
}

// Return the xy coordinates of the mouse position
function mousePos(e) {
    const rect = canvas.getBoundingClientRect();
    return new maplibregl.Point(
        e.clientX - rect.left - canvas.clientLeft,
        e.clientY - rect.top - canvas.clientTop
    );
}

function mouseDown(e) {
    // Continue the rest of the function if the shiftkey is pressed.
    if (!(e.shiftKey && e.button === 0)) return;
        if(isCreateTicket){
            // Disable default drag zooming when the shift key is held down.
            // that.map.dragPan.disable();
            
            // Call functions for the following events
            document.addEventListener('mousemove', onMouseMove);
            document.addEventListener('mouseup', onMouseUp);
            document.addEventListener('keydown', onKeyDown);
            
            // Capture the first xy coordinates
            start = mousePos(e);
        }
}
    
function onMouseMove(e) {
    // Capture the ongoing xy coordinates
    current = mousePos(e);
    
    // Append the box element if it doesnt exist
    if (!box) {
        box = document.createElement('div');
        $(box).css('background-color', 'rgba(66, 135, 245, 0.5)');
        box.classList.add('boxdraw');
        canvas.appendChild(box);
    }
    
    const minX = Math.min(start.x, current.x),
    maxX = Math.max(start.x, current.x),
    minY = Math.min(start.y, current.y),
    maxY = Math.max(start.y, current.y);
    
    // Adjust width and xy position of the box element ongoing
    const pos = `translate(${minX}px, ${minY}px)`;
    box.style.transform = pos;
    box.style.width = maxX - minX + 'px';
    box.style.height = maxY - minY + 'px';
}

function onMouseUp(e) {
    // Capture xy coordinates
    finish([start, mousePos(e)]);
}

function onKeyDown(e) {
    // If the ESC key is pressed
    if (e.keyCode === 27) finish();
}

async function finish(bbox) {
    // Remove these events now that finish has been called.
    document.removeEventListener('mousemove', onMouseMove);
    document.removeEventListener('keydown', onKeyDown);
    document.removeEventListener('mouseup', onMouseUp);

    var headerArr = [
        "create_work_order",
        "id",
        "system_id",
        "system_name",
        "asset_class",
        "asset_identifier",
        "asset_sub_class",
        "type"
    ]
    
    if (box) {
        box.parentNode.removeChild(box);
        box = null;
    }
    
    // If bbox exists. use this value as the argument for `queryRenderedFeatures`
    if (bbox) {
        featuresArr = []
        var features = _map.queryRenderedFeatures(bbox);
        for(var i = 0; i < features.length; i++){
            var isFound = _containsObject(featuresArr, features[i]["properties"]["id"])
            if(!isFound){
                featuresArr.push(features[i]["properties"])
            }
        }
        
        var html_str = ``
        var html_head = ''

        if(featuresArr.length > 0){
            for(var i = 0; i < featuresArr.length; i++){
                html_str += "<tr>";
                var properties = features[i]["properties"]
                console.log(properties["system_id"])
    
                for(var x = 0; x < headerArr.length; x++){
                    var col = headerArr[x]
                    if(i == 0){
                        var str_a = col.replaceAll("name", "");
                        str_a = str_a.replaceAll("_", " ");
                        var str_b = str_a.split(' ').map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
                        html_head += `<td>${str_b}</td>`
                    }
    
                    if(properties["system_id"] > 0 ){
                        if(col == 'create_work_order'){
                            html_str += `<td><input type='checkbox' name='feature-create-ticket' value='${i}' /></td>`;
                        }
                        else{
                            html_str += "<td data-num='"+i+"'>"+ properties[col] +"</td>";
                        }
                    }
                    
                }
                html_str += "</tr>";
            }
            
            document.getElementById("featuresSelectedHead").innerHTML = `<tr>${html_head}</tr>`
            document.getElementById("featuresSelectedBody").innerHTML = html_str
    
            $("#featuresSelectedTable").fancyTable({
                sortColumn:false,
                pagination: true,
                perPage:10,
                globalSearch:true,
                searchable:true,
            });
    
            $("#modal_features_selected").show()
        }
    }
}

define([
    'backbone',
    'jquery',
    'js/map/layers/control','fancyTable',
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
            // Variable to hold the starting xy coordinates
            // when `mousedown` occured.
            
            event.register(this, evt.COMMUNITY_CHANGE, this.communityChanged);
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

            _map = this.map

            this.map.on('click', function (e) {
                event.trigger(evt.MAP_CLICKED, e.lngLat);
            });

            // Set `true` to dispatch the event before other functions
            // call it. This is necessary for disabling the default map
            // dragging behaviour.
            canvas = this.map.getCanvasContainer();
            canvas.addEventListener('mousedown', mouseDown, true);

            const draw = new MapboxDraw({
                displayControlsDefault: false,
                controls: {
                    polygon: true,
                    trash: true
                }
            });
            // this.map.addControl(draw, 'bottom-left');
        
            this.map.on('draw.create', updateArea);
            this.map.on('draw.delete', updateArea);
            this.map.on('draw.update', updateArea);
            var that = this
            function updateArea(e) {
                const data = draw.getAll();
                var coord = data["features"][0]["geometry"]["coordinates"][0]
                // var features = turf.pointsWithinPolygon()
                console.log(coord)
                var polygonBoundingBox = turf.bbox(data["features"][0])
                var southWest = [polygonBoundingBox[0], polygonBoundingBox[1]];
                var northEast = [polygonBoundingBox[2], polygonBoundingBox[3]];

                var northEastPointPixel = map.project(northEast);
                var southWestPointPixel = map.project(southWest);

                console.log("bbox", polygonBoundingBox)
                let all_layers = that.map.getStyle().layers
                let layers = []
                for(var i = 0; i < all_layers.length; i++){
                    if(all_layers[i]["source"] == sourceLayerID){
                        layers.push(all_layers[i]["id"])
                    }
                }
                let result = that.map.queryRenderedFeatures([southWestPointPixel, northEastPointPixel], {layers: layers})
                let selectedFeatures = []
                for(var i = 0; i < result.length; i++){
                    if(selectedFeatures.indexOf(result[i]["properties"]) == -1){
                        selectedFeatures.push(result[i]["properties"])
                    }
                }
                console.log("selectedFeatures",selectedFeatures)
            }

            document.getElementById("addToWorkOrderBtn").addEventListener("click", async function(){

                console.log(featuresArr)
                
                var checkboxArr = [];
                $('input[name="feature-create-ticket"]:checked').each(function() {
                    checkboxArr.push(this.value)
                })

                if(checkboxArr.length > 0){
                    var featuresSelectedArr = []
                    for(var x = 0; x < checkboxArr.length; x++){
                        var index = checkboxArr[x]
                        var id = featuresArr[index]["id"]
                        this.detailLoading = true
                        const feature = await RequestFn.promiseGet(
                            urls.feature_data.replaceAll('0', id)
                        )
                        featuresSelectedArr.push(feature)
                    }

                    for(var i = 0; i < featuresSelectedArr.length; i++){
                        event.trigger(evt.TICKET_BASKET_ADD_FEATURE, featuresSelectedArr[i])
                    }

                    $("#modal_features_selected").hide()
                }
                else{
                    alert("Please select a feature to continue")
                }

            })

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
        },

        communityChanged(community) {
            if (community?.get('organisation')?.permissions?.create_ticket) {
                isCreateTicket = true
            } else {
                isCreateTicket = false
            }
        },

    });
});