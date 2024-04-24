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
            var lat;
            var lon;
            if (!geojson?.geometry?.coordinates || !geojson?.geometry?.coordinates[0]) {
                try {
                    var name = geojson.properties["name"];
                    var province = geojson.properties["province"];

                    $.ajax({
                        type: 'GET',
                        url: domain + "api/latlon/",
                        data: {name: name, province: province, country: "Canada"},
                        success: function(response){
                            console.log(response);
                            lat = response.lat;
                            lon = response.lon;

                            var sw = new maplibregl.LngLat(lon - 0.01, lat + 0.01);
                            var ne = new maplibregl.LngLat(lon + 0.01, lat - 0.01);
                            var bounds = new maplibregl.LngLatBounds(sw, ne);
                            event.trigger(evt.MAP_FLY, bounds);

                        },
                        error: function(response){
                            console.log(response)
                        }
                    });
                    return;
                } catch (error) {
                    return
                }
            }
            this.map.getSource(this.layerId).setData(geojson);
            try {
                const coordinates = geojson.geometry.coordinates[0][0];
                var sw = new maplibregl.LngLat(coordinates[0][1] - 0.01, coordinates[0][0] + 0.01);
                var ne = new maplibregl.LngLat(coordinates[0][1] + 0.01, coordinates[0][0] - 0.01);
                var bounds = new maplibregl.LngLatBounds(sw, ne);
                event.trigger(evt.MAP_FLY, bounds);
            } catch (error) {
                console.log("could not fetch geomtry from geojson");
            }
        },
    });
});