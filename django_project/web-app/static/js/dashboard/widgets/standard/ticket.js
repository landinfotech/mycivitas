/**
 * This widget handling list of ticket and also the detail of ticket
 */
define([
    'underscore',
    'js/widgets/base'], function (_, Base) {
    return Base.extend({
        id: 'widget-ticket',
        name: 'Tickets',
        icon: '<i class="fa fa-ticket" aria-hidden="true"></i>',
        description: 'Showing list of tickets that are opened.',
        layerStyle: '',
        url: urls.community_ticket,

        init: function () {
            this.data = {};
            this.community = null;
            event.register(this, evt.COMMUNITY_CHANGE, this.communityChanged);
        },
        /** Abstract function called after render
         */
        postRender: function () {
            if (!this.community) {
                this.$content.html(templates.LOADING);
            } else {
                this.renderData();
            }
        },
        /** When community changed,
         * rerender ticket list by community
         * @param community
         */
        communityChanged(community) {
            this.community = community;
            this.rerender();
        },
        renderData: function () {
            if (!this.data[this.community.id]) {
                this.$content.html(templates.LOADING)

                // get the data
                if (this.request) {
                    this.request.abort()
                }
                const that = this;
                const url = this.url.replace('0', this.community.id);
                this.request = RequestFn.get(
                    url, {}, null,
                    function (data) {
                        that.data[that.community.id] = data;
                        that.render();
                    },
                    function () {
                        /**fail**/
                    })
            } else {
                const data = this.data[this.community.id];
                if (data.length === 0) {
                    this.$content.html(this.templateNoData);
                    return
                }
                this.$content.html('');
                for (let idx = 0; idx < data.length; idx++) {
                    const ticket = data[idx];
                    this.$content.append(
                        templates.TICKET_DETAIL({
                            url: urls.ticket_detail.replaceAll(0, ticket.id),
                            title: ticket.title,
                            description: ticket.description,
                            date: ticket.created
                        })
                    )
                }
            }
        },
    });
});