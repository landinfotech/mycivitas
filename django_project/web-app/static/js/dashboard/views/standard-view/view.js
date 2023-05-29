/**
 * This view is showing the detail of assets
 * And also showing the ticket of assets
 */
define([
    'js/views/base',
    'js/widgets/standard/ticket',
    'js/widgets/asset-management/consequence-of-failure',
    'js/widgets/asset-management/probability-of-failure',
    'js/widgets/asset-management/risk',
], function (Base, Ticket, ConsequenceOfFailure, ProbabilityOfFailure, Risk) {
    return Base.extend({
        name: 'Standard',
        init: function () {
            this.widgets = [
                new Ticket(), new ConsequenceOfFailure(),
                new ProbabilityOfFailure(), new Risk()];
        }
    });
});