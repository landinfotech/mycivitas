/**
 * This controls QGIS layers to be drawn to map
 * It draws element of html to select/unselect the layer
 */
define([
    'backbone',
    'jquery',
    'js/map/layers/main-layer',
    'js/map/layers/selected-layer-feature'
], function (
    Backbone, $, MainLayer, SelectedLayer) {
    return Backbone.View.extend({
        selectedLayer: null,
        layer: null,
        systemNamesArr: null,
        assetNamesArr: null,

        initialize: function (mapView) {
            const that = this;
            this.$el_classification = $('#classification')
            this.$el_risk = $('#risk_list')
            this.$el_system = $('#system_list')
            this.$el_asset = $('#asset_list')
            this.style = '';
            this.currentClass;
            this.mapView = mapView;
            this.selectedLayer = new SelectedLayer(mapView);
            event.register(this, evt.LAYER_STYLE_CHANGE, this.changeStyle);
            event.register(this, evt.COMMUNITY_CHANGE, this.communityChanged);

            $('#layer-list-toggle').click(function () {
                $('#left-top').toggleClass('show');
            })

            $('#hideLegendBtn').click(function () {
                $('.legendURL').hide()
                document.getElementById("see-layer-list").innerHTML = `<i style="margin-left: -17px;" class="fa fa-chevron-down" aria-hidden="true"></i> See Filter List`
                document.getElementById("hide-layer-list").innerHTML = `<i style="margin-left: -17px;" class="fa fa-chevron-up" aria-hidden="true"></i> Hide Filter List`
            })

            $('#showLegendBtn').click(function () {
                $('.legendURL').show()
                document.getElementById("see-layer-list").innerHTML = `<i style="margin-left: -17px;" class="fa fa-chevron-down" aria-hidden="true"></i> See Layer List`
                document.getElementById("hide-layer-list").innerHTML = `<i style="margin-left: -17px;" class="fa fa-chevron-up" aria-hidden="true"></i> Hide Layer List`
            })

            $.each(HeatmapLayers, function (layerName, values) {
                const id = layerName.replaceAll(' ', '-');
                // restructure the html
                const html = templates.HEATMAP_SELECTION_ROW({
                    layername: layerName,
                    id: id,
                    legendURL: ''
                });
                that.$el_risk.append(html);
            });

            // this.assetSubClassLogic(this.$el_asset ,_communityID)
            this.assetClassLogic(this.$el_asset ,_communityID)
            this.systemNameLogic(this.$el_system ,_communityID)

            this.changeStyle('')

            // Create layers
            this.layer = new MainLayer(mapView);

            //event when radio is clicked
            this.$el_risk.find('.risk-selection').click(function () {
                if($(this).is(':checked')){
                    // TO DO: remove heatmap styles
                }
                const $row = $(this).closest('.layer-row')
                $row.toggleClass('active');

                var layerName = $($row).data("layername")
                event.trigger(evt.HEATMAP_CHANGED, layerName);
            })
        },

        assetClassLogic: async function(el, community_id){
            const resp_asset = await fetch(`/api/asset-class/${community_id}`);
            assetNamesArr = await resp_asset.json();
            const that = this
            var _asset_count = 0
            var assetLayerLegends = {
                'Natural': "/static/legends/1_natural_assets_.png",
                'Structures': "/static/legends/3_structures_.png",
                'Transportation Network': "/static/legends/4_transportation_network_.png",
                'Water Supply': "/static/legends/6_water_supply_.png",
                'Wastewater Collection': "/static/legends/5_wastewater_collection_.png",
                'Stormwater Collection': "/static/legends/2_stormwater_collection_.png",
                'Electrical Network':  "/static/legends/7_electrical_network_.png",
            };
            var layerImagesFolder = ""
            $.each(assetNamesArr, function (layerName, values) {
                layerName = assetNamesArr[_asset_count]["asset_class"]
                const id = layerName.replaceAll(' ', '-');
                // restructure the html
                const asset_html = templates.LAYER_SELECTION_DROPDOWN_ROW({
                    layername: assetNamesArr[_asset_count]["asset_class"],
                    id: id,
                    asset: assetNamesArr[_asset_count]["asset_identifier"],
                    legendURL: assetLayerLegends[layerName]
                });
                el.append(asset_html);
                var assetSubArr = assetNamesArr[_asset_count]["asset_sub_class"]
                var sub_assets = `<div class="asset-dropdown">`
                for(var i = 0; i < assetSubArr.length; i++){
                    sub_assets += `
                    <div 
                    class="layer-row-sub active"
                    data-layername="${assetSubArr[i]["asset"]}" 
                    data-layertype="${assetSubArr[i]["type"]}" >
                        <i class="fa fa-check-square asset-sub-selection" aria-hidden="true"></i>
                        <i class="fa fa-square-o asset-sub-selection" aria-hidden="true"></i>
                        ${assetSubArr[i]["asset"]}
                    </div>`
                }
                sub_assets += `</div>`
                document.getElementById(id + "_sub" ).innerHTML = sub_assets
                _asset_count++
            });
            // event when checkbox clicked
            el.find('.asset-class-selection').click(function () {
                const $row = $(this).closest('.layer-row')
                $row.toggleClass('active');
                var subClass = $row.find('.layer-row-sub');
                subClass.each(function(el){
                    if($row.hasClass('active')){
                        $(this).addClass('active');
                    }
                    else{
                        $(this).removeClass('active');
                    }
                })
                that.activeClassesChangedLayers();
            })
            
            el.find('.asset-sub-selection').click(function () {
                const $parent= $(this).closest('.layer-row')
                const $row = $(this).closest('.layer-row-sub')
                if($parent.hasClass('active')){
                    $row.toggleClass('active');
                    that.activeClassesChangedLayers();
                }
                else{
                    $row.toggleClass('active');
                }
            })
            this.activeClassesChangedLayers();
        },

        systemNameLogic: async function(el, community_id){
            const that = this
            const resp_system = await fetch(`/api/system-names/${community_id}`);
            systemNamesArr = await resp_system.json();
            var _system_count = 0
            $.each(systemNamesArr, function (layerName, values) {
                layerName = systemNamesArr[_system_count]["system_name"]
                const id = layerName.replaceAll(' ', '-');
                // restructure the html
                const html = templates.SYSTEM_SELECTION_ROW({
                    layername: systemNamesArr[_system_count]["system_name"],
                    id: id + "_sytemname",
                    legendURL: ''
                });
                el.append(html);
                _system_count++
            });

            // event when checkbox clicked
            el.find('.fa-check-square, .fa-square-o').click(function () {
                const $row = $(this).closest('.layer-row')
                $row.toggleClass('active');
                that.activeClassesChangedSystemNames();
            })
            this.activeClassesChangedSystemNames();
        },

        /** Update legend
         */
        updateLegends: function(style) {
            for (const [layerName, value] of Object.entries(HeatmapLayers)) {
                let html = value.legends.map(url=>{
                    return `<img src="${url}">`
                })
                const id = layerName.replaceAll(' ', '-');
                const $legend = $(`#${id} img`);
                $legend.replaceWith(`<div>${html.join('')}</div>`);
            }
        },
        /** Get Legend url
         */
        changeStyle: function (style) {
            this.updateLegends(style)
            // if it is null
            // style does not need to be changed
            if (style === null) {
                return
            }
            if (this.style === style) {
                return
            }
            this.style = style;
        },

        /**
         * Return layer name that active
         */
        getActiveLayersName: function () {
            let names = [];
            $('#asset_list .layer-row.active').each(function () {
                
                var subClass = $(this).find('.layer-row-sub.active');
                var subClassArr = []
                var typeArr = []
                subClass.each(function(){
                    subClassArr.push($(this).data('layername'))
                    var typeStr = $(this).data('layertype')
                    var _typeArr = typeStr.split(",")
                    for(var i = 0; i< _typeArr.length; i++){
                        typeArr.push(_typeArr[i])
                    }
                    
                })

                names.push({
                    "asset_class": $(this).data('layername'), 
                    "asset_identifier": $(this).data('asset'),  
                    "asset_sub_class":subClassArr,
                    "asset_type":typeArr
                })
            })
            return names
        },

        /**
         * Return layer name that active
         */
        getActiveSystemName: function () {
            let names = [];
            $('#system_list .active').each(function () {
                names.push($(this).data('layername'))
            })
            return names
        },

        /**
         * Activate classes changed
         */
        activeClassesChangedLayers: function () {
            const qgisLayers = this.getActiveLayersName();

            // For active class for graph
            let classes = [];
            let subClasses = [];
            let assetTypes = [];
            qgisLayers.forEach(function (layerName) {
                classes = classes.concat(layerName["asset_identifier"]);
                var subClass = layerName["asset_sub_class"]
                var typeClass = layerName["asset_type"]
                subClass.forEach(function(_subLayer){
                    subClasses = subClasses.concat(_subLayer)
                })

                typeClass.forEach(function(_type){
                    assetTypes = assetTypes.concat(_type)
                })
            });
            if(JSON.stringify(this.currentClass) !== JSON.stringify(classes)){
                this.currentClass = classes
                event.trigger(evt.CLASSES_LIST_CHANGE, classes);
            }
            this.layer.asset_sub_class = subClasses
            this.layer.type = assetTypes
            this.layer.classes = classes
            this.layer.filterLayers()
        },
        /**
         * Activate classes changed
         */
        activeClassesChangedSystemNames: function () {
            const qgisLayers = this.getActiveSystemName();

            // For active class for graph
            let system_names = [];
            for(var i = 0; i < qgisLayers.length; i++){
                system_names = system_names.concat(qgisLayers[i]);
            }
            
            this.layer.system_names = system_names
            this.layer.filterLayers()
        },

        communityChanged(community) {
            if(community){
                document.getElementById("system_list").innerHTML = "<p>Organization</p>"
                this.systemNameLogic(this.$el_system ,community.id)

                document.getElementById("asset_list").innerHTML = "<p>Classification</p>"
                this.assetClassLogic(this.$el_asset ,community.id)
            }
        },
    });
});