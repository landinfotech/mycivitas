/**
 * This widget showing the asset/feature detail
 */
define([
    'underscore',
    'js/widgets/base'], function (_, Base) {
    return Base.extend({
        id: 'features-detail',
        name: 'Assets',
        description: 'This panel shows the assets that are selected in map.',
        features: {},
        community: null,
        featureIDKey: 'Feature ID',
        actionButton: '<span id="download_exported_id" class="export-assets-table"><i class="fa fa-download" aria-hidden="true" title="Download data as csv"></i></span>',

        init: function () {
            this.data = [];
            this.templateNoData = templates.PLEASE_CLICK_MAP;

            event.register(this, evt.FEATURE_LIST_FETHCING, this.dataFetching);
            event.register(this, evt.FEATURE_LIST_FETHCED, this.dataFetched);
            event.register(this, evt.COMMUNITY_CHANGE, this.communityChanged);
            event.register(this, evt.FEATURE_REMOVED_FROM_BASKET, this.featureRemovedFromBasket);

            function getRequests() {
                var s1 = location.search.substring(1, location.search.length).split('&'),
                    r = {}, s2, i;
                for (i = 0; i < s1.length; i += 1) {
                    s2 = s1[i].split('=');
                    r[decodeURIComponent(s2[0]).toLowerCase()] = decodeURIComponent(s2[1]);
                }
                return r;
            };

            if (window.location.href.indexOf("feature") > -1) {
                var QueryString = getRequests();
                var id = QueryString["feature"];
                var community = QueryString["community"];

                setTimeout(function(){
                    // $.ajax({
                    //     type: 'GET',
                    //     url: "/api/community/" + community, //Replace your URL here
                    //     success: function(response){
                    //         event.trigger(evt.COMMUNITY_CHANGE, response);
                    //         event.trigger(this, evt.COMMUNITY_GEOJSON_CHANGE, response);
                    //     },
                    //     error: function () {
                    //         // Code After Erroe
                    //     }
                    // });
                    $.ajax({
                        type: 'GET',
                        url: "/api/feature/"+id+"/data", //Replace your URL here
                        success: function(response){
                            //code after success
                            event.trigger(evt.FEATURE_HIGHLIGHTED, response);
                        },
                        error: function () {
                            // Code After Erroe
                        }
                    });
                },2000)
            }
            
        },
        /** When the data is starting fetching
         */
        dataFetching: function () {
            this.data = null;
            event.trigger(evt.FEATURE_HIGHLIGHTED, null);
            this.render();
        },
        /** When the data has been fetched
         */
        dataFetched: function (data) {
            /** success **/
            this.data = data;
            this.render();
            const ID = $(this.$rightPanel.find('.content:visible')[0]).attr('id');
            if (ID !== this.id) {
                this.show();
            }
        },
        renderData: function () {
            const that = this;
            let selectedID = '';
            let _feature;
            
            if (this.data.length > 0) {
                let htmls = [];
                let tabs = []
                that.features = {};
                this.data.forEach(feature => {
                    if (!feature.properties.feature_id) {
                        feature.properties.feature_id = feature.properties[that.featureIDKey];
                    }
                    const ID = feature.properties.feature_id;
                    if (!ID) {
                        return false;
                    }
                    that.features[ID] = feature;
                    _feature = that.features[ID];

                    // if selectedID empty, make ID as default selectedID
                    if (!selectedID) {
                        selectedID = ID;
                    }

                    // create tab
                    tabs.push(
                        templates.FEATURE_DETAIL_TAB({
                            id: ID,
                            active: ID === selectedID ? 'active' : ''
                        })
                    );

                    // create content
                    let isInBasket = false;
                    event.trigger(evt.TICKET_BASKET_CHECK, feature, function (output) {
                        isInBasket = output;
                    });
                    let html = '';

                    // TODO:
                    //  This should be don on backend
                    const properties = {};
                    for (let [key, value] of Object.entries(feature.properties)) {
                        if (["Maintenance Cost", "Annual Reserve", "Renewal Cost"].includes(key)) {
                            if (value) {
                                value = that.community.get('currencyFormatter').format(value)
                            }
                        }
                        properties[key] = value;
                    }
                    html += templates.FEATURE_INFO({
                        value: properties
                    })
                    htmls.push(
                        templates.FEATURE_DETAIL_TAB_PANE({
                            id: ID,
                            name: feature.id.replaceAll('_', ' '),
                            basketClass: isInBasket ? 'remove' : '',
                            canCreateTicket: that.community?.get('organisation')?.permissions?.create_ticket,
                            active: ID === selectedID ? 'true active show' : '',
                            html: html
                        })
                    );
                });
                this.$content.html(`<ul class="nav nav-tabs">${tabs.join('')}</ul>`);
                this.$content.append(`<div class="tab-content">${htmls.join('')}</div>`);

                // We need to get ticket list
                this.data.forEach(feature => {
                    const ID = feature.properties.feature_id;
                    const url = urls.feature_ticket_list.replace('0', ID);
                    const $ticketView = that.$content.find(`#ticket-view-${ID}`);
                    const $ticketCount = that.$content.find(`#ticket-count-${ID}`);
                    this.request = RequestFn.get(
                        url, {}, null,
                        function (data) {
                            $ticketView.html('');
                            $ticketCount.html(`(${data.length})`);
                            if (data.length === 0) {
                                $ticketView.html('<div class="indicator">No ticket</div>')
                                return
                            }
                            for (let idx = 0; idx < data.length; idx++) {
                                const ticket = data[idx];
                                $ticketView.append(
                                    templates.TICKET_DETAIL({
                                        url: urls.ticket_detail.replaceAll(0, ticket.id),
                                        title: ticket.title,
                                        description: ticket.description,
                                        date: ticket.created
                                    })
                                )
                            }
                        },
                        function () {
                            $ticketView.html('<div class="indicator">Error fetching ticket</div>')
                        }
                    )
                })

                document.getElementById("download_exported_id").addEventListener("click", function(){

                    htmlStringBody = "";
                    for (var key in _feature["properties"]) { 
                        htmlStringBody += "<tr><td><input type='checkbox' checked name='export_csv'/></td><td><strong class='asset-key'>"+ key +"<strong></td><td class='asset-value'>"+ _feature["properties"][key] +"</td></tr>"
                    }
                    document.getElementById("table_body").innerHTML = htmlStringBody;

                    let myModal = new bootstrap.Modal(document.getElementById('modal_export'), {});
                    myModal.show();
                    
                });

                function exportToCsv(filename, rows) {
                    var processRow = function (row) {
                        var finalVal = '';
                        for (var j = 0; j < row.length; j++) {
                            var innerValue = row[j] === null ? '' : row[j].toString();
                            if (row[j] instanceof Date) {
                                innerValue = row[j].toLocaleString();
                            };
                            var result = innerValue.replace(/"/g, '""');
                            if (result.search(/("|,|\n)/g) >= 0)
                                result = '"' + result + '"';
                            if (j > 0)
                                finalVal += ',';
                            finalVal += result;
                        }
                        return finalVal + '\n';
                    };
                
                    var csvFile = '';
                    for (var i = 0; i < rows.length; i++) {
                        csvFile += processRow(rows[i]);
                    }
                
                    var blob = new Blob([csvFile], { type: 'text/csv;charset=utf-8;' });
                    if (navigator.msSaveBlob) { // IE 10+
                        navigator.msSaveBlob(blob, filename);
                    } else {
                        var link = document.createElement("a");
                        if (link.download !== undefined) { // feature detection
                            // Browsers that support HTML5 download attribute
                            var url = URL.createObjectURL(blob);
                            link.setAttribute("href", url);
                            link.setAttribute("download", filename);
                            link.style.visibility = 'hidden';
                            document.body.appendChild(link);
                            link.click();
                            document.body.removeChild(link);
                        }
                    }
                }


                document.getElementById("exportcsv").addEventListener("click", function(){

                    let checkedElem = document.getElementsByName("export_csv");
                    let checkedElemNum = [];

                    for(let i = 0; i < checkedElem.length; i++ ){
                        if(checkedElem[i].checked){
                            checkedElemNum.push(i)
                        }
                    }

                    let finalKeys = [];
                    let finalValues = [];

                    let x = 0;
                    for (var key in _feature["properties"]) { 
                        for(let i = 0; i < checkedElemNum.length; i++){
                            if(checkedElemNum[i]==x){
                                finalKeys.push(key)
                                finalValues.push(_feature["properties"][key])
                            }
                        }
                        x++;
                    }

                    let rows = [
                        finalKeys,
                        finalValues
                    ]

                    exportToCsv(_feature["properties"]["Community"], rows)
                });

                
                // Check feature already in basket or not
                this.$content.find('.feature-create-ticket').click(function () {
                    const ID = $(this).data('feature-id');
                    const feature = that.features[ID]
                    if ($(this).hasClass('remove')) {
                        $(this).removeClass('remove');
                        event.trigger(evt.TICKET_BASKET_REMOVE_FEATURE, feature)
                    } else {
                        $(this).addClass('remove');
                        event.trigger(evt.TICKET_BASKET_ADD_FEATURE, feature)
                    }
                });
                this.$content.find('.nav-tabs a').click(function () {
                    that.selectFeature($(this).data('id'));
                });

                // show/hide group in table
                this.$content.find('table').find('.header').click(function () {
                    that.$content.find('table').find(`tbody[data-group='${$(this).data('group')}']`).toggle();
                    $(this).toggleClass('hide')
                });

                // toggler button for view
                this.$content.find('.detail-button').click(function () {
                    that.$content.find('.toggle .col').removeClass('active');
                    that.$content.find('.detail-button').addClass('active');
                    that.$content.find('.detail-view').show();
                    that.$content.find('.ticket-view').hide();
                });
                this.$content.find('.ticket-button').click(function () {
                    that.$content.find('.toggle .col').removeClass('active');
                    that.$content.find('.ticket-button').addClass('active');
                    that.$content.find('.detail-view').hide();
                    that.$content.find('.ticket-view').show();
                });
            } else {
                this.$content.html(templates.NODATAFOUND);
            }
            
            this.selectFeature(selectedID);
        },
        /***
         * When feature selected, highlight it to map
         */
        selectFeature: function (ID) {
            event.trigger(evt.FEATURE_HIGHLIGHTED, this.features[ID]);
        },
        /** When community changed,
         * @param community
         */
        communityChanged(community) {
            this.data = [];
            this.community = community;
            this.render();
        },
        /** When feature removed from basket
         * @param feature
         */
        featureRemovedFromBasket(feature) {
            const that = this;
            $('.feature-create-ticket.remove').each(function () {
                if ($(this).data('feature-id') === feature.properties[that.featureIDKey]) {
                    $(this).toggleClass('remove');
                }
            });
        },
    });
});