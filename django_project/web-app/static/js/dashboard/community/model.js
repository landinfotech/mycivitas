/**
 * This is model of community
 */
define([
    'backbone'], function (Backbone) {
    return Backbone.Model.extend({
        urlRoot: '/api/community',
        initialize: function () {
            this.on('sync', this.fetched, this);
            this.on('error', this.fetchError, this);
            this.fetchedDone = false
        },
        parse: function (data, options) {
            try {
                data['currencyFormatter'] = new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: data.currency,
                });
            } catch (e) {
                data['currencyFormatter'] = new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD',
                });
            }
            return data;
        },
        /** Called when community selected from dropdown
         */
        selected: function () {
            if (!this.fetchedDone) {
                this.fetch();
                this.fetchedDone = true;
                return
            }
            event.trigger(evt.COMMUNITY_GEOJSON_CHANGE, {
                "type": "Feature",
                "properties": {
                    "id": this.id,
                    "name": this.get('name'),
                    "region": this.get('region'),
                    "province": this.get('province'),
                },
                "geometry": this.get('geometry')
            });
            event.trigger(evt.COMMUNITY_CHANGE, this);
        },
        /** When the community data fetched
         */
        fetched: function () {
            this.selected()
        },
        fetchError: function (error) {

        }
    });
});