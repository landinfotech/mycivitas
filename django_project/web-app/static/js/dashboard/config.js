let mapView;
let map;

require.config(requireConfig);
require([
    // libs
    'jquery',
    'backbone',
    'underscore',

    // projects static
    'js/event',
    'js/request',
    'js/templates',
    'js/map/map',
    'js/controller',
    'js/community/controller',
], function (
    $, Backbone, _, _Event, _Request, _Templates,
    Map, DashboardController, CommunityController) {

    new _Templates();
    event = new _Event();
    RequestFn = new _Request();

    // initiate all view
    mapView = new Map(()=>{
        map = mapView.map;

        // init system/community controller
        new DashboardController();
        new CommunityController(map);

    });
});