/**
 * Showing widget in progress
 */
define([
    'underscore',
    'js/widgets/base'], function (_, Base) {
    return Base.extend({
        id: 'in-progress',
        name: 'In progress',
        /** Abstract function called when data is presented
         */
        postRender: function () {
            this.$content.html(templates.COMING_SOON);

        }
    });
});