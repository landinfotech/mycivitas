/**
 * This is model of community
 */
define([
    'backbone',
    'fancyTable',], function (Backbone) {
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

                htmlStr += "<td style='display:none'><a href='" + host + "/community-map/?feature=" + feature_id+"'>" + host + "/community-map/?feature=" + feature_id+"</a></td>";
                
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
            document.getElementById("loadingScreenTable").style.display = "block"
            $.ajax({
                type: 'GET',
                url: "/api/asset-download/" + this.attributes.id, //Replace your URL here
                success: function(response){
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
                            headStr += "<td>Zoom</td>"
                            headStr += "<td>Feature ID</td>"
                        }
                        else{
                            headStr += "<td>"+ str_b +"</td>"
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

                        htmlStr += "<td style='display:none'><a href='" + host + "/community-map/?feature=" + feature_id+"'>" + host + "/community-map/?feature=" + feature_id+"</a></td>";
                        
                        htmlStr += "</tr>";
                        
                    })

                    document.getElementById("table_show").innerHTML = htmlStr;
                    isRan = true

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
            });
            
        },
        /** When the community data fetched
         */
        fetched: function () {
            this.selected()
        },
        fetchError: function (error) {

        }
    });
});