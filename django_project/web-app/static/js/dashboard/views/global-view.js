/**
 * This view is showing the detail of assets
 * And also showing the ticket of assets
 */
define([
    'js/views/base',
    'js/widgets/global/create-ticket',
    'js/widgets/global/features-detail',
], function (Base, CreateTicket, FeaturesDetail) {
    return Base.extend({
        name: 'Standard',
        init: function () {
            // create layer
            const $globalToggleButton = $('#global-toggle-button');
            this.widgets = [
                new FeaturesDetail($globalToggleButton),
                new CreateTicket($globalToggleButton)
            ];
        }
    });
});