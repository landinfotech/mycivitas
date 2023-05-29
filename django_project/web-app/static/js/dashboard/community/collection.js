/**
 * This contains collection of community
 */
define([
    'backbone',
    'js/community/model'], function (Backbone, Community) {
    return Backbone.Collection.extend({
        model: Community,
        url: '/api/community'
    });
});