/**
 * This is controller for community
 */
define([
    'backbone',
    'js/community/collection'], 
    function (Backbone, Community) {
    return Backbone.View.extend({
        layerId: 'community',
        community: null,
        layer: null,
        el: '#community',
        initialize: function (map) {
            const that = this;
            this.map = map;
            const $ul = that.$el.find('ul');
            this.$el.find('.selection').click(function () {
                $ul.slideToggle('fast');
            });

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
                id: this.layerId,
                source: this.layerId,
                type: 'line',
                paint: {
                    'line-color': "#f44a52",
                    'line-opacity': 0.3,
                    'line-width': 2
                }
            });
            event.register(this, evt.COMMUNITY_GEOJSON_CHANGE, this.communityGeojsonChanged);
            event.register(this, evt.FEATURE_PAN, this.featureChanged);

            // fetch community
            this.collection = new Community();
            this.collection.fetch({
                success: function () {
                    if (that.collection.models.length > 0) {
                        let defaultCommunity = 0;
                        that.collection.models.forEach(function (model, idx) {
                            if (user.communityID) {
                                if (model.id === user.communityID) {
                                    defaultCommunity = idx;
                                }
                            }
                            $ul.append(`<li value="${model.id}">${model.get('name')} (${model.get('code')})</li>`)
                        });

                        // remove loading and show the list
                        that.$el.find('.loading').remove();
                        that.$el.find('.detail').show();

                        // onclick list
                        $ul.find('li').click(function () {
                            if (that.collection.get($(this).val()) !== that.community) {
                                that.change(that.collection.get($(this).val()))
                            }
                        });
                        $($ul.find('li')[defaultCommunity]).click();
                        $ul.hide();
                    }
                }
            })
        },
        /** Change community **/
        change: function (community) {
            this.community = community;
            this.$el.find('.name').html(`${community.get('name')} (${community.get('code')})`);
            this.$el.find('.region').html(community.get('region'));
            this.$el.find('.province').html(community.get('province'));
            event.trigger(evt.COMMUNITY_CHANGE, null);
            community.selected();
            setCookie('community', community.id);
        },
        /** Called when the geojson has changed
         * @param geojson
         */
        communityGeojsonChanged: function (geojson) {
            if (!geojson?.geometry?.coordinates || !geojson?.geometry?.coordinates[0]) {
                return
            }
            const coordinates = geojson.geometry.coordinates[0][0]
            this.map.getSource(this.layerId).setData(geojson);
            var bounds = coordinates.reduce(function (bounds, coord) {
                return bounds.extend(coord);
            }, new maplibregl.LngLatBounds(coordinates[0], coordinates[0]));
            event.trigger(evt.MAP_FLY, bounds);
        },
        featureChanged: function (geojson) {
            if (!geojson?.geometry?.coordinates || !geojson?.geometry?.coordinates[0]) {
                return
            }
            console.log("feature new", geojson)
            var coordinates;
            if(geojson.geometry.type === "Point"){
                coordinates = geojson.geometry.coordinates
            }
            else if(geojson.geometry.type === "LineString"){
                coordinates = geojson.geometry.coordinates[0]
            }
            else if(geojson.geometry.type === "Polygon"){
                coordinates = geojson.geometry.coordinates[0][0]
            }
            var sw = new maplibregl.LngLat(coordinates[0] - 0.001, coordinates[1] - 0.001);
            var ne = new maplibregl.LngLat(coordinates[0] + 0.001, coordinates[1] + 0.001);
            var bounds = new maplibregl.LngLatBounds(sw, ne);
            event.trigger(evt.MAP_FLY, bounds);
        },
    });
});