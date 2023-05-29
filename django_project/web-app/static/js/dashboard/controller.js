/**
 * This is main control for the View or Style
 */
define([
    'backbone',
    'js/views/global-view',
    'js/views/standard-view/view'
], function (
    Backbone, GlobalView, StandardView) {
    return Backbone.View.extend({
        el: '#styles',
        style: null,
        views: [],
        initialize: function () {
            const that = this;
            const $ul = that.$el.find('ul');
            this.$el.find('.selection').click(function () {
                $ul.slideToggle('fast');
            })

            // render views as list
            this.globalView = new GlobalView();
            this.change(this.globalView);

            this.views = [new StandardView()];
            this.views.forEach(function (view, idx) {
                $ul.append(`<li value="${idx}">${view.name}</li>`)
            });

            if (this.views.length > 1) {
                this.$el.show()
            }

            // onclick list
            $ul.find('li').click(function () {
                if (that.views[$(this).val()] !== that.style) {
                    that.change(that.views[$(this).val()])
                }
            });
            $($ul.find('li')[0]).click();
            $ul.hide()
        },
        /** Change dashboard style **/
        change: function (style) {
            // render layer to map
            // remove previous style
            if (this.style) {
                event.trigger(evt.MAP_REMOVE_LAYER, style.layer);
            }

            this.style = style;
            this.$el.find('.name').html(style.name);

            // destroy every view and render selected one
            this.views.forEach(function (view, idx) {
                view.destroy()
            });
            style.activate();

            // add layer
            if (style.layer) {
                event.trigger(evt.MAP_ADD_LAYER, style.layer);
                event.trigger(evt.MAP_FLY, style.layer.getBounds());
            }
        },
    });
});