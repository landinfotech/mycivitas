/**
 * This widget showing donut graph for failure assets
 */
define([
    'underscore',
    'js/widgets/asset-management/base'], function (_, Base) {
    return Base.extend({
        id: 'consequence-of-failure',
        name: 'Consequence of Failure',
        icon: 'C',
        layerStyle: 'cof',
        url: urls.community_cof,
        legend: {
            Minor: '#1a9641',
            Moderate: '#a6d96a',
            Significant: '#ffff00',
            Major: '#fdae61',
            Catastrophic: '#d7191c',
            Unknown: '#959595'
        }
    });
});