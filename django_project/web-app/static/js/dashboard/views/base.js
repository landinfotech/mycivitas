/**
 * Abstract class for style
 * Style is the class that having specific widget and also have specific layers on map
 */
define([
    'backbone'], function (Backbone) {
    return Backbone.View.extend({
        widgets: [],
        active: false,
        data: null,
        layer: null,
        systems: null,
        initialize: function () {
            event.register(this, evt.SYSTEM_CHANGE, this.systemChangedParent);
            this.init();
        },
        /**
         *  This is abstract function that called after initialize
         */
        init: function () {

        },
        /** Activate the view
         */
        activate: function () {
            this.active = true;
            this.renderWidgets();
            this.widgets[0].show();

            // call system changed when it's activated
            if (this.systems) {
                this.systemChanged(this.systems)
            }
        },
        /** Render widgets of style
         */
        renderWidgets: function () {
            if (this.active) {
                this.widgets.forEach(function (widget) {
                    widget.render()
                });
            }
        },
        /** destroy view
         * **/
        destroy: function () {
            this.widgets.forEach(function (widget) {
                widget.destroy()
            });
            this.active = false;
        },
        /**
         *  This is abstract function that calls when the style activated
         */
        systemChangedParent: function (systems) {
            this.systems = systems;
            if (this.active) {
                this.systemChanged(systems)
            }
        },
        /**
         *  This is abstract function that called after system changed
         */
        systemChanged: function (systems) {

        },
        /** When map done on drawing
         */
        mapDrawDone: function (layer) {

        }
    });
});