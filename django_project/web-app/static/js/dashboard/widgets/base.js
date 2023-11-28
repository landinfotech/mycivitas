/**
 * Abstract class for widget
 * Widget is the class that have specific content that will be rendered on the right side panel
 */
define([
    'backbone',
    'jquery',
    'js/map/layers/main-layer',
    'js/map/map',
    'js/map/layers/selected-layer-feature'
    ], function (Backbone) {
    return Backbone.View.extend({
        id: null,
        name: null,
        description: '',
        icon: '<i class="fa fa-exclamation-circle" aria-hidden="true"></i>',
        actionButton: '',
        layerStyle: null,
        

        /** Initialize the widget
         */
        initialize: function ($toggleButtonWrapper) {
            this.data = null;
            this.$rightPanel = $('#right-panel');
            this.$wrapper = $('#right-panel .inner');
            this.$wrapperButton = $toggleButtonWrapper ? $toggleButtonWrapper : $('#widget-toggle-button');
            this.templateNoData = templates.NODATAFOUND;
            
            this.mapView = mapView;
            // events
            event.register(this, evt.MAP_CLICKED, this._mapClicked);
            event.register(this, evt.WIDGETS_HIDE, this.hide);
            this.init();
        },
        /**This is abstract function that called after initialize
         */
        init: function () {

        },
        /** Return ID of widget         *
         * @returns {string}
         */
        widgetID: function () {
            return `#${this.id} .content-widget`
        },
        /** Function to rerender the widget if active
         */
        rerender: function () {
            if (this.active) {
                this.render()
            }
        },
        /** Function to render the widget
         */
        render: function () {
            // append to wrapper
            const that = this;
            this.active = true;
            if (this.$wrapper.find(`#${this.id}`).length === 0) {
                this.$wrapper.append(templates.WIDGET_CONTENT({
                    id: this.id,
                    name: this.name,
                    description: this.description,
                    actionButton: this.actionButton
                }));
                this.$wrapperButton.append(
                    templates.WIDGET_BUTTON({
                        id: this.id,
                        name: this.name,
                        icon: this.icon
                    })
                )
                this.$content = $(this.widgetID());

                this.$el = $(`#${this.id}`);
                this.$button = $(`#${this.id}-button`);
                this.$button.click(function () {
                    that.show();
                });
                this.$button.find('.widget-notification-message').click(function () {
                    that.hideNotificationMessage();
                    return false;
                })
            }
            this.postRender();
        },
        /**
         * Hide message of notification
         */
        hideNotificationMessage: function () {
            const $message = this.$button.find('.widget-notification-message');
            $message.animate({
                opacity: 0,
                right: "-=50"
            }, 300, function () {
                $message.hide();
            });
        },
        /** Function when the widget show
         */
        show: function () {
            const that = this;
            const ID = $(this.$rightPanel.find('.content:visible')[0]).attr('id');
            if (!this.$rightPanel.hasClass('hidden') && ID === that.id) {
                this.$rightPanel.animate({ right: "-350px" }, 100, function () {
                    that.$rightPanel.addClass('hidden');
                });
            } else {
                if (this.$rightPanel.hasClass('hidden')) {
                    this.$rightPanel.removeClass('hidden');
                    this.$rightPanel.animate({ right: "0" }, 100);
                }
                if (ID !== that.id) {
                    event.trigger(evt.WIDGETS_HIDE);
                    this.$button.removeClass('hidden');
                    this.$el.show();
                    this.afterShow()
                }
            }
            event.trigger(evt.LAYER_STYLE_CHANGE, this.layerStyle);
        },
        /** Function show if the widget already show
         */
        afterShow: function () {
            const that = this;
            const ID = $(this.$rightPanel.find('.content:visible')[0]).attr('id');
            //trigger event set up in map.js
            if(ID == "widget-ticket" || ID == "consequence-of-failure" || ID == "probability-of-failure" || ID == "risk"){
                event.trigger(evt.HEATMAP_CHANGED, ID);
            }
            
        },
        /** Function when the widget hidden
         */
        hide: function () {
            if (this.$button) {
                this.$button.addClass('hidden');
            }
            this.$el.hide();
            this.afterHide();
        },
        /** Function hide if the widget already hidden
         */
        afterHide: function () {

        },
        /** Function destroying widget
         */
        destroy: function () {
            this.active = false;
            this.postDestroy();
            this.$el.remove();
            if (this.$button) {
                this.$button.remove();
            }
            this.afterHide();
        },
        /** Abstract function called after render
         */
        postRender: function () {
            // if data is null, show loading
            if (this.data == null) {
                this.$content.html(templates.LOADING);
            } else if (Object.keys(this.data).length === 0) {
                this.$content.html(this.templateNoData)
            } else {
                this.$content.html('');
                this.renderData();
            }
        },
        /** Abstract function called after post render if data is presented
         */
        renderData: function () {

        },
        /** Abstract function called when widget destroyed
         */
        postDestroy: function () {

        },
        /** When map clicked and check if active
         */
        _mapClicked: function (latlng) {
            if (this.active) {
                this.mapClicked(latlng)
            }
        },
        /** When map clicked
         */
        mapClicked: function (latlng) {

        },
        /** Show notification marker
         */
        showNotification: function (message) {
            this.$button.find('.widget-notification').show();
            if (message) {
                const that = this;
                const $message = this.$button.find('.widget-notification-message')
                $message.css('opacity', 1);
                $message.css('right', '40px');
                $message.html(message);
                $message.show();
                setTimeout(function () {
                    that.hideNotificationMessage();
                }, 3000);
            }
        },
        /** hide notification marker
         */
        hideNotification: function () {
            this.$button.find('.widget-notification').hide();
        }
    });
});