/**
 * This is model of community
 */
define([
    'backbone',
    'fancyTable', 'filter-multi-select',], function (Backbone) {
    return Backbone.Model.extend({
        urlRoot: '/api/community',
        initialize: function () {
            this.page_num = 1;
            this.on('sync', this.fetched, this);
            this.on('error', this.fetchError, this);
            this.fetchedDone = false
        },
        parse: function (data, options) {
            try {
                data['currencyFormatter'] = new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: data.currency,
                });
            } catch (e) {
                data['currencyFormatter'] = new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD',
                });
            }
            return data;
        },
        featurePagination: function(featureArr){
           if(featureArr != undefined){
            var host = window.location.protocol + "//" + window.location.host;

            featureArr.forEach(function(row){
                htmlStr += "<tr class='exportfiltered'>";
                var feature_id;
                
                for(var key in row){
                    
                    if(key==='feature_id'){
                        feature_id = row[key]
                        htmlStr += "<td class='getFeatureMap' id='"+row[key]+"'><button class='btn btn-primary' onClick='showFeatureMap("+row[key]+")'><span class='material-symbols-outlined'>search</span></button></td>"
                        htmlStr += "<td>"+ row[key] +"</td>";
                    }
                    else{
                        htmlStr += "<td>"+ row[key] +"</td>";
                    }
                    
                }

                htmlStr += `<td style='display:none'><a href='${host}/community-map/?feature=${feature_id}'>${host}/community-map/?feature=${feature_id}</a></td>`;
                
                htmlStr += "</tr>";
                
            })

            document.getElementById("table_show").innerHTML = htmlStr;
           }

        },
        /** Called when community selected from dropdown
         */
        selected: function () {
            if (!this.fetchedDone) {
                this.fetch();
                this.fetchedDone = true;
                return
            }
            event.trigger(evt.COMMUNITY_GEOJSON_CHANGE, {
                "type": "Feature",
                "properties": {
                    "id": this.id,
                    "name": this.get('name'),
                    "region": this.get('region'),
                    "province": this.get('province'),
                },
                "geometry": this.get('geometry')
            });
            
            event.trigger(evt.COMMUNITY_CHANGE, this);

            function createTable(response){
                //code after success
               document.getElementById("filteredhead").innerHTML = "";
               document.getElementById("table_show").innerHTML = "";
               let htmlStr = "";
               let headStr = "";
               
               headStr += "<tr class='exportfiltered feature-filter'>";
               for(var key in response[0]){

                   var str_a = key.replaceAll("name", "");
                   str_a = str_a.replaceAll("_", " ");
                   var str_b = str_a.split(' ').map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
                   if(str_b == 'Feature Id'){
                       headStr += "<td class='getFeatureMap'>Zoom</td>"
                       headStr += "<td class='feature_id col-filter'>Feature ID</td>"
                   }
                   else{
                       headStr += "<td class='"+ key +" col-filter'>"+ str_b +"</td>"
                   }

               }
               headStr += "</tr>";
               document.getElementById("filteredhead").innerHTML = headStr;
               var host = window.location.protocol + "//" + window.location.host;

               response.forEach(function(row){
                   htmlStr += "<tr class='exportfiltered'>";
                   var feature_id;
                   
                   for(var key in row){
                       
                       if(key==='feature_id'){
                           feature_id = row[key]
                           htmlStr += "<td class='getFeatureMap' id='"+row[key]+"'><button class='btn btn-primary' onClick='showFeatureMap("+row[key]+")'><span class='material-symbols-outlined'>search</span></button></td>"
                           htmlStr += "<td>"+ row[key] +"</td>";
                       }
                       else{
                           htmlStr += "<td>"+ row[key] +"</td>";
                       }
                       
                   }

                   htmlStr += `<td style='display:none'><a href='${host}/community-map/?feature=${feature_id}'>${host}/community-map/?feature=${feature_id}</a></td>`;
                   
                   htmlStr += "</tr>";
                   
               })

               document.getElementById("table_show").innerHTML = htmlStr;

               // document.getElementById("table-data").style.display = "";
               document.getElementById("loadingScreenTable").style.display = "none"

               $("#filteredTable").fancyTable({
                   sortColumn:false,
                   pagination: true,
                   perPage:10,
                   globalSearch:false,
                   searchable:true,
               });
            }

            var community_id = this.attributes.id
            
            custom_list = [
                "feature_id",
                "community_name",
                "system_name",
                "sub_class_name",
                "asset_type_name",
                "feature_description",
                "quantity",
                "sub_class_unit_description",
                "reported_renewal_cost",
                "condition_id",
                "condition_name",
                "inspection_date",
                "install_date",
                "age",
                "remaining_years",
                "pof_id",
                "pof_name",
                "cof_id",
                "cof_name",
                "risk_value",
                "risk_level",
                "area",
                "reported_length",
                "diameter",
                "material",
                "display_label",
                "province_name",
                "province_code",
                "regoin_code",
                "community_code",
                "system_id",
                "class_name",
                "class_description",
                "sub_class_id", 
                "sub_class_description", 
                "sub_class_unit_id", 
                "sub_class_unit_name",
                "type_id", 
                "asset_type_description", 
                "view_name", 
                "reported_area", 
                "lookup_unit_maintenance_cost", 
                "lookup_unit_renewal_cost", 
                "input_maintenance_cost", 
                "input_renewal_cost", 
                "maintenance_cost_calc_method", 
                "renewal_cost_calc_method", 
                "reported_maintenance_cost", 
                "lookup_lifespan", 
                "input_lifespan", 
                "lifespan_calc_method", 
                "reported_lifespan", 
                "projected_sustainable_investment", 
                "brand", 
                "model", 
                "contractor", 
                "width", 
                "display_id", 
                "power_output", 
                "size",
                "load_rating", 
                "depth", 
                "footprint", 
                "floor_area", 
                "height", 
                "structure_id", 
                "service", 
                "capacity", 
                "stakeholder",
                "species", 
                "gauge", 
                "phase", 
                "specification", 
                "cores", 
                "primary_voltage", 
                "secondary_voltage", 
                "voltage", 
                "current", 
                "communication", 
                "account", 
            ]

            //default view
            document.getElementById("loadingScreenTable").style.display = "block"
            $.ajax({
                type: 'GET',
                url: "/api/asset-default-download/" + this.attributes.id, //Replace your URL here
                success: function(response){
                    createTable(response)
                },
                error: function () {
                    // Code After Erroe
                }
            });

            $('#column-filter').on('change', function() {

                var selected = $(this).find(":selected").val()
                switch(selected){
                    case "default":
                        $.ajax({
                            type: 'GET',
                            url: "/api/asset-default-download/" + community_id, //Replace your URL here
                            success: function(response){
                                createTable(response)
                                $("#custom_filter").hide();
                            },
                            error: function () {
                                // Code After Erroe
                            }
                        })
                    break;
                    
                    case "detailed":
                        $.ajax({
                            type: 'GET',
                            url: "/api/asset-detailed-download/" + community_id, //Replace your URL here
                            success: function(response){
                                createTable(response)
                                $("#custom_filter").hide();
                            },
                            error: function () {
                                // Code After Erroe
                            }
                        })
                    break;
                    
                    case "custom":
                        $("#custom_filter").show();
                        var _html = `
                        <br>
                        <label>Select Columns</label>
                        <select multiple name="custom_filter_select" id="custom_filter_select" class="filter-multi-select">
                        `
                        for(var y = 0; y < custom_list.length; y++){
                            var str_a = custom_list[y].replaceAll("name", "");
                            str_a = str_a.replaceAll("_", " ");
                            var str_b = str_a.split(' ').map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
                            _html += `<option value="${custom_list[y]}">${str_b}</option>`
                        }
                        _html += `</select><br>
                        <button id="apply-custom-filter" class="btn btn-primary">Apply Filters</button>`
                        document.getElementById('custom_filter').innerHTML = _html
                        $('#custom_filter_select').filterMultiSelect();

                        $("#apply-custom-filter").click(function(e) {

                            var getJson = function (b) {
                                var result = $.fn.filterMultiSelect.applied
                                    .map((e) => JSON.parse(e.getSelectedOptionsAsJson(b)))
                                    .reduce((prev,curr) => {
                                        prev = {
                                        ...prev,
                                        ...curr,
                                        };
                                        return prev;
                                    });
                                return result;
                            }
                            var selectedObj = JSON.parse(JSON.stringify(getJson(true),null,"  "))
                            var selectedArr = selectedObj["custom_filter_select"]

                            if(selectedArr.length > 0){
                                $.ajax({
                                    type: 'POST',
                                    url: "/api/asset-custom-download/", //Replace your URL here
                                    data: {'pk': community_id, 'selected': selectedArr, 'csrfmiddlewaretoken': csrf_token},
                                    success: function(response){

                                        document.getElementById("filteredhead").innerHTML = "";
                                        document.getElementById("table_show").innerHTML = "";
                                        let htmlStr = "";
                                        let headStr = "";
                                        var isFeatureBegin = false

                                        for(var i = 0; i < selectedArr.length; i++){
                                            if(selectedArr[i] == "feature_id"){
                                                isFeatureBegin = true
                                                break
                                            }
                                        }

                                        if (!isFeatureBegin){
                                            selectedArr.unshift("feature_id")
                                        }
                                        
                                        headStr += "<tr class='exportfiltered feature-filter'>";
                                        for(var i = 0; i < selectedArr.length; i++){
                                            var str_a = selectedArr[i].replaceAll("name", "");
                                            str_a = str_a.replaceAll("_", " ");
                                            var str_b = str_a.split(' ').map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
                                            if(str_b == 'Feature Id' && isFeatureBegin ){
                                                headStr += "<td class='getFeatureMap'>Zoom</td>"
                                                headStr += "<td class='feature_id col-filter'>Feature ID</td>"
                                            }
                                            else if(str_b == 'Feature Id' && !isFeatureBegin ){
                                                headStr += "<td class='getFeatureMap'>Zoom</td>"
                                            }
                                            else{
                                                headStr += "<td class='"+ selectedArr[i] +" col-filter'>"+ str_b +"</td>"
                                            }

                                        }
                                        headStr += "</tr>";
                                        document.getElementById("filteredhead").innerHTML = headStr;
                                        var host = window.location.protocol + "//" + window.location.host;
                                        var data_len = response[0].length

                                        for(var i = 0; i < data_len; i++){

                                            htmlStr += "<tr class='exportfiltered'>";
                                            var feature_id;

                                            for(var x = 0; x < selectedArr.length; x++){
                                                
                                                var key = selectedArr[x]
                                                var item = response[x][i][key]

                                                if(key==='feature_id' && isFeatureBegin){
                                                    feature_id = item
                                                    htmlStr += `<td class='getFeatureMap' id='${item}'>
                                                    <button class='btn btn-primary'onClick='showFeatureMap(${item})'>
                                                    <span class='material-symbols-outlined'>search</span>
                                                    </button>
                                                    </td>`
                                                    htmlStr += "<td class='feature_id col-filter'>"+ item +"</td>";
                                                }
                                                else if(key==='feature_id' && !isFeatureBegin){
                                                    feature_id = item
                                                    htmlStr += `<td class='getFeatureMap' id='${item}'>
                                                    <button class='btn btn-primary'onClick='showFeatureMap(${item})'>
                                                    <span class='material-symbols-outlined'>search</span>
                                                    </button>
                                                    </td>`
                                                }
                                                else{
                                                    htmlStr += "<td class='"+ key +" col-filter'>"+ item +"</td>";
                                                }
                                            }

                                            htmlStr += `
                                            <td style='display:none'>
                                            <a href='${host}/community-map/?feature=${feature_id}'>${host}/community-map/?feature=${feature_id}</a>
                                            </td>`;
                                            
                                            htmlStr += "</tr>";
                                            
                                        }

                                        document.getElementById("table_show").innerHTML = htmlStr;

                                        // document.getElementById("table-data").style.display = "";
                                        document.getElementById("loadingScreenTable").style.display = "none"

                                        $("#filteredTable").fancyTable({
                                            sortColumn:false,
                                            pagination: true,
                                            perPage:10,
                                            globalSearch:false,
                                            searchable:true,
                                        });
                                    },
                                    error: function () {
                                        // Code After Erroe
                                    }
                                })
                            }
                        })
                    break;
                }
            });
            
        },
        fetched: function () {
            this.selected()
        },
        fetchError: function (error) {

        }
    });
});