/**
 * This widget showing donut graph for failure assets
 */
define([
    'underscore',
    'js/widgets/asset-management/base'], function (_, Base) {
    return Base.extend({
        id: 'risk',
        name: 'Risk',
        icon: 'R',
        layerStyle: 'risk',
        url: urls.community_risk,
        legend: {
            Minimal: '#1a9641',
            Low: '#a6d96a',
            Medium: '#ffff00',
            High: '#fdae61',
            Extreme: '#d7191c',
            Unknown: '#959595'
        }
    });
});