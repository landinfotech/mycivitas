/**
 * This widget showing donut graph for failure assets
 */
define([
    'underscore',
    'js/widgets/asset-management/base'], function (_, Base) {
    return Base.extend({
        id: 'probability-of-failure',
        name: 'Probability of Failure',
        icon: 'P',
        layerStyle: 'pof',
        url: urls.community_pof,
        legend: {
            Rare: '#1a9641',
            Unlikely: '#a6d96a',
            Possible: '#ffff00',
            Likely: '#fdae61',
            'Almost Certain': '#d7191c',
            Unknown: '#959595'
        }
    });
});