/**
 * Handler of notification
 */
define([
    'backbone',
    'jquery'
], function (Backbone, $) {
    return Backbone.View.extend({
        el: '#notification',
        initialize: function () {
            event.register(this, evt.NOTIFICATION_ADD, this.addNotification);
            this.template = _.template($('#-notification').html());
            this.templateContent = _.template($('#-notification-content').html());
        },
        /**
         * Add notification to the html
         * @param id
         * @param type : string
         *      type of notification :
         *      - error
         *      - warning
         *      - question (default)
         * @param message : string
         * @param autoClose
         */
        addNotification: function (id, type, message, autoClose) {
            let $element = $('#notification-' + id);
            if ($element.length === 0) {
                $(this.template({
                    id: id,
                    icon: type,
                    message: message
                })).appendTo($(this.el)).on({
                    'click': function () {
                        if (autoClose !== false) {
                            $(this).hide('slide', { direction: 'left' }, function () {
                                $(this).remove()
                            });
                        }
                    }
                }).show('slide', { direction: 'left' });
            } else {
                $element.html(this.templateContent({
                    icon: type,
                    message: message
                }));
            }
        }
    });
});