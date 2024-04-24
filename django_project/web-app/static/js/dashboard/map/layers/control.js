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

            $('#filterLegendBtn').click(function(){
                el = document.getElementById("expandLayer")
                var style = window.getComputedStyle(el);
                if(style.display == "none"){
                  $("#expandLayer").show()
                }
                else{
                  $("#expandLayer").hide()
                }
            })

            $('#filterListBtn').click(function(){
                el = document.getElementById("innerFilterList")
                var style = window.getComputedStyle(el);
                if(style.display == "none"){
                  $("#innerFilterList").show()
                }
                else{
                  $("#innerFilterList").hide()
                }
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
            var currentHeatmapLayer = ""
            //event when radio is clicked
            this.$el_risk.find('.risk-selection').click(function () {
                var newHeatmapLayer = $(this).data("heatmap")
                const $row = $(this).closest('.layer-row')
                $row.toggleClass('active');
                if(newHeatmapLayer == currentHeatmapLayer){
                    // TO DO: remove heatmap styles
                    $(this).prop('checked', false)
                    $row.toggleClass('active');
                    event.trigger(evt.HEATMAP_CHANGED, "default");
                    currentHeatmapLayer = ""
                }
                else{
                    currentHeatmapLayer = newHeatmapLayer
                    var layerName = $($row).data("layername")
                    event.trigger(evt.HEATMAP_CHANGED, layerName);
                }
               
            })
        },

        assetClassLogic: async function(el, community_id){
            const resp_asset = await fetch(`/api/asset-class/${community_id}`);
            assetNamesArr = await resp_asset.json();
            const that = this
            var _asset_count = 0
            $.each(assetNamesArr, function (layerName, values) {
                layerName = assetNamesArr[_asset_count]["asset_class"]
                const id = layerName.replaceAll(' ', '-');
                // restructure the html
                const asset_html = templates.LAYER_SELECTION_DROPDOWN_ROW({
                    layername: assetNamesArr[_asset_count]["asset_class"],
                    id: id,
                    asset: assetNamesArr[_asset_count]["asset_identifier"],
                    legendURL: ''
                });
                el.append(asset_html);
                var assetSubArr = assetNamesArr[_asset_count]["asset_sub_class"]
                var sub_assets = `<div class="asset-dropdown">`
                for(var i = 0; i < assetSubArr.length; i++){
                    var layerstyle = []
                    for(var y = 0; y < assetSubArr[i]["view_name"].length; y++){
                        if(!layerstyle.includes(assetSubArr[i]["view_name"][y])){
                            layerstyle.push(assetSubArr[i]["view_name"][y])
                        }
                    }

                    var subID = assetSubArr[i]["asset"].replaceAll(' ', '-');
                    
                    sub_assets += `
                    <div 
                    class="layer-row-sub active"
                    data-layername="${assetSubArr[i]["asset"]}" 
                    data-layertype="${assetSubArr[i]["type"]}" 
                    data-layerstyle="${layerstyle}">
                        <a aria-hidden="true" data-toggle="collapse" href="#${id}_${subID}_type"
                        role="button" aria-expanded="false" aria-controls="collapseExample" class="collapsed button-collapse">
                            <i class="fa fa-caret-down"></i>
                            <i class="fa fa-caret-up"></i>
                        </a>
                        <i class="fa fa-check-square asset-sub-selection" aria-hidden="true"></i>
                        <i class="fa fa-square-o asset-sub-selection" aria-hidden="true"></i>
                        ${assetSubArr[i]["asset"]}
                    `
                    var types = assetSubArr[i]["type"]
                    var combinations = assetSubArr[i]["combination_id"]
                    
                    var typeHTML = ``

                    for(var x = 0; x < types.length; x++){
                        typeHTML += `
                        <div 
                        class="layer-row-type active "
                        data-layername="${types[x]}" 
                        data-layertype="${types[x]}" 
                        data-combinationid=${combinations[x]}
                        data-layerstyle="${layerstyle}">
                            <i class="fa fa-check-square asset-type-selection" aria-hidden="true"></i>
                            <i class="fa fa-square-o asset-type-selection" aria-hidden="true"></i>
                            ${types[x]}
                        </div>`
                    }

                    sub_assets +=
                    `<div class="layer-list collapse" id="${id}_${subID}_type">
                        ${typeHTML}
                    </div>
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
                    
                }
                else{
                    $row.toggleClass('active');
                }

                var subClass = $row.find('.layer-row-type');
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

            el.find('.asset-type-selection').click(function () {
                const $parent= $(this).closest('.layer-row-sub')
                const $row = $(this).closest('.layer-row-type')
                if($parent.hasClass('active')){
                    $row.toggleClass('active');
                }
                else{
                    $parent.toggleClass('active');
                    $row.toggleClass('active');
                }

                that.activeClassesChangedLayers();
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
                var subTypeClass = $(this).find('.layer-row-type.active');
                var subClassArr = []
                var typeArr = []
                var styleArr = []
                var subTypeArr = []
                subClass.each(function(){
                    subClassArr.push($(this).data('layername'))
                    var typeStr = $(this).data('layertype')
                    var _typeArr = typeStr.split(",")
                    for(var i = 0; i< _typeArr.length; i++){
                        if(!typeArr.includes(_typeArr[i])){
                            typeArr.push(_typeArr[i])
                        }
                    }
                    
                    var styleStr = $(this).data('layerstyle')
                    var _styleArr = styleStr.split(",")
                    for(var i = 0; i< _styleArr.length; i++){
                        if(!styleArr.includes(_styleArr[i])){
                            styleArr.push(_styleArr[i])
                        }
                    }
                })

                subTypeClass.each(function(){
                    subTypeArr.push($(this).data('combinationid'))
                })

                names.push({
                    "asset_class": $(this).data('layername'), 
                    "asset_identifier": $(this).data('asset'),  
                    "asset_sub_class":subClassArr,
                    "asset_type":typeArr,
                    "view_name": styleArr,
                    "sub_type": subTypeArr
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
            let styleTypes = [];
            let subTypes = [];
            qgisLayers.forEach(function (layerName) {
                classes = classes.concat(layerName["asset_identifier"]);
                var subClass = layerName["asset_sub_class"]
                var typeClass = layerName["asset_type"]
                var styleClass = layerName["view_name"]
                var subTypeClass = layerName["sub_type"]
                subClass.forEach(function(_subLayer){
                    subClasses = subClasses.concat(_subLayer)
                })

                typeClass.forEach(function(_type){
                    assetTypes = assetTypes.concat(_type)
                })

                subTypeClass.forEach(function(_type){
                    subTypes = subTypes.concat(_type)
                })

                styleClass.forEach(function(_style){
                    if(_style != ""){
                        styleTypes = styleTypes.concat(_style)
                    }
                })
            });
            if(JSON.stringify(this.currentClass) !== JSON.stringify(classes)){
                this.currentClass = classes
                event.trigger(evt.CLASSES_LIST_CHANGE, classes);
            }

            this.layer.asset_sub_class = subClasses
            this.layer.type = assetTypes
            this.layer.classes = classes
            this.layer.view_name = styleTypes
            this.layer.sub_types = subTypes
            this.layer.filterLayers()
            console.log(styleTypes)
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