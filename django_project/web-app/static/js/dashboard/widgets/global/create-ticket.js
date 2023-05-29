/**
 * This widget handling list of ticket and also the detail of ticket
 */
define([
    'jquery',
    'jqueryUI',
    'underscore',
    'js/widgets/base'], function ($, jqueryUI, _, Base) {
    return Base.extend({
        id: 'widget-create-ticket',
        name: 'Create Ticket',
        icon: '<i class="fa fa-ticket" aria-hidden="true"></i>',
        description: 'Create new ticket from the selected asset(s).',
        dataInDict: {},
        community: null,
        notificationMessage: 'When you are ready<br>click here to make a ticket.',

        init: function () {
            this.data = [];
            this.templateNoData = templates.PLEASE_ADD_FEATURE;
            this.templateNoAccess = templates.NO_ACCESS;
            event.register(this, evt.TICKET_BASKET_ADD_FEATURE, this.addFeatureToBasket);
            event.register(this, evt.TICKET_BASKET_REMOVE_FEATURE, this.removeFeatureFromBasket);
            event.register(this, evt.TICKET_BASKET_CHECK, this.checkFeatureInBasket);
            event.register(this, evt.COMMUNITY_CHANGE, this.communityChanged);
        },
        /** Add feature to ticket basket
         * @param feature
         */
        addFeatureToBasket(feature) {
            if (!this.dataInDict[feature.id]) {
                this.dataInDict[feature.id] = feature;
            }
            this.data.push(feature);
            this.showNotification(this.notificationMessage);
            this.render();
        },
        /** Remove feature to ticket basket
         * @param feature
         */
        removeFeatureFromBasket(feature) {
            const that = this;
            event.trigger(evt.FEATURE_REMOVED_FROM_BASKET, feature);
            if (this.dataInDict[feature.id]) {
                delete this.dataInDict[feature.id]
            }
            if (Object.keys(this.dataInDict).length === 0) {
                this.hideNotification();
            }
            this.data = [];
            $.each(this.dataInDict, function (key, feature) {
                that.data.push(feature);
            });
            this.render();
        },
        /** Check feature is in basket
         * @param feature
         * @param callbackFunction
         */
        checkFeatureInBasket(feature, callbackFunction) {
            callbackFunction(this.dataInDict[feature.id])
        },
        /** Abstract function called after render
         */
        postRender: function () {
            // if data is null, show loading
            if (!this.community) {
                this.$content.html(this.templateNoAccess);
            } else if (this.data == null) {
                this.$content.html(templates.LOADING);
            } else if (Object.keys(this.data).length === 0) {
                this.$content.html(this.templateNoData);
            } else {
                this.$content.html('');
                this.renderData();
            }
        },
        renderData: function () {
            const that = this;
            const html = templates.CREATE_TICKET();
            this.$content.append(html);
            $('#id_start_date').datepicker({
                minDate: 0,
                dateFormat: 'yy-mm-dd'
            });
            $("#id_start_date").datepicker(
                "setDate", new Date()
            );
            $('#id_due_date').datepicker({
                minDate: 0,
                dateFormat: 'yy-mm-dd'
            });
            if (Object.keys(this.dataInDict).length !== 0) {
                this.showNotification();
            }
            const $list = $('#feature-ticket-list');
            let ids = [];
            for (let idx = 0; idx < this.data.length; idx++) {
                const feature = this.data[idx];
                const ID = feature.properties.feature_id;
                ids.push(ID);
                $list.append(templates.TICKET_FEATURE({
                    id: ID,
                    name: feature.id
                }))
            }
            $('#feature-id-input').val(ids.join(','));
            this.$content.find('.fa-minus-circle').click(function () {
                that.removeFeatureFromBasket(
                    that.dataInDict[$(this).data('id')]);
            })
            this.$content.find('#click-here').click(function () {
                event.trigger(evt.FEATURE_LIST_FETHCED, that.data);
                return false;
            })

            const $formGroup = $('#id_recurring_type').closest('.form-group');
            $formGroup.hide();
            $('#id_queue').change(function () {
                $('#id_recurring_type').val('');
                if (recurring_queues.includes(parseInt($(this).val()))) {
                    $formGroup.show();
                    $formGroup.find('select').prop('disabled', false);
                } else {
                    $formGroup.hide();
                    $formGroup.find('select').prop('disabled', true);
                }
            })
            const $assignTo = $('#id_assigned_to');
            $assignTo.html('<option value="" selected="">--------</option>');
            $.each(this.community.get('organisation').operators, function (index, operator) {
                $assignTo.append(`<option value="${operator[0]}">${operator[1]}</option>`)
            });
            recurringTypeInputEvent();
            inputEvent();

        },
        /** When community changed,
         * @param community
         */
        communityChanged(community) {
            this.data = [];
            this.dataInDict = {};
            this.hideNotification();
            if (community?.get('organisation')?.permissions?.create_ticket) {
                this.community = community;
            } else {
                this.community = null;
            }
            this.rerender();
        },
    });
});