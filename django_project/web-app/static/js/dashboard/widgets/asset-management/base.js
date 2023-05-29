/**
 * Showing widget in progress  
 */
define([
    'underscore',
    'fancyTable',
    'js/widgets/base'], function (_, fancyTable, Base) {
    return Base.extend({
        id: 'in-progress',
        name: 'In progress',
        actionButton: '<a target="_blank"><i class="fa fa-download" aria-hidden="true" title="Download data as csv"></i></a>',
        /** Abstract function called when data is presented
         */
        init: function () {
            this.data = {};
            this.community = null;
            this.classes = null;
            event.register(this, evt.COMMUNITY_CHANGE, this.communityChanged);
            event.register(this, evt.CLASSES_LIST_CHANGE, this.classesChanged)

            this.renewalBar = null;
            this.renewalDoughnut = null;
        },
        /** Abstract function called after render
         */
        postRender: function () {
            this.$download = this.$el.find('.action-button');
            this.$download.prop('disabled', true);
            this.$download.off();
            if (!this.community) {
                this.$content.html(templates.LOADING);
            } else {
                this.renderData();
            }
        },
        /** Get the data
         */
        getData: function () {
            const that = this;
            const data = this.data[this.community.id];
            if (data) {
                return data.filter(row => (!that.classes || that.classes.includes(row['class_name'])));

            }
            return data;
        },
        /** Abstract function called after post render if data is presented
         */
        renderData: function () {
            if (!this.getData()) {
                this.$content.html(templates.LOADING)
                // get the data
                if (this.request) {
                    this.request.abort()
                }
                const that = this;
                const url = this.url.replace('0', this.community.id);
                this.request = RequestFn.get(
                    url, {}, null,
                    function (data) {
                        that.data[that.community.id] = data;
                        that.render();
                    },
                    function () {
                        /**fail**/
                    })
            } else {

                const that = this;
                const data = this.getData();
                const downloadUrl = urls.reporter_data_download.replace('0', this.community.id);
                if (data.length === 0) {
                    this.$content.html(this.templateNoData);
                    return
                }
                this.$download.prop('disabled', false);
                this.$download.find('a').attr('href', downloadUrl);
                // render graph and bar
                if (this.$content.find('.donut-graph').length === 0) {
                    this.$content.html(
                        templates.ASSET_MANAGEMENT_WIDGET({
                            title: this.name
                        })
                    );
                    this.renewalDoughnut = this.initChart(
                        this.$content.find('.renewal-doughnut'), 'doughnut');
                    this.renewalBar = this.initChart(
                        this.$content.find('.renewal-bar'), 'bar', true);
                }

                // data by summary type
                let bySummaryType = {};
                let bySubClassNameAndSummaryType = {};
                
                let isRan = false;
                document.getElementById("table-data").style.display = "none";
                $.ajax({
                    type: 'GET',
                    url: "/api/asset-download/" + this.community.id, //Replace your URL here
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

                        $("#filteredTable").fancyTable({
                            sortColumn:false,
                            pagination: true,
                            perPage:10,
                            globalSearch:false,
                            searchable:true,
                        });

                        document.getElementById("table-data").style.display = "";
                        
                    },
                    error: function () {
                        // Code After Erroe
                    }
                });

                data.forEach(function (row) {
                    const summary_type = capitalize(row.summary_type ? row.summary_type.trim() : 'Unknown');
                    const sub_class_name = capitalize(row.sub_class_name ? row.sub_class_name.trim() : 'Unknown');
                    let maintenance_cost = row.maintenance_cost ? row.maintenance_cost : 0;
                    let renewal_cost = row.renewal_cost ? row.renewal_cost : 0;
                    let cost = renewal_cost;

                    // get the cost by summary type
                    if (!bySummaryType[summary_type]) {
                        bySummaryType[summary_type] = 0;
                    }
                    bySummaryType[summary_type] += cost;

                    // get the cost by sub class and summary type
                    if (!bySubClassNameAndSummaryType[sub_class_name]) {
                        bySubClassNameAndSummaryType[sub_class_name] = {
                            values: {},
                            total: 0
                        };
                    }
                    if (!bySubClassNameAndSummaryType[sub_class_name]['values'][summary_type]) {
                        bySubClassNameAndSummaryType[sub_class_name]['values'][summary_type] = 0;
                    }
                    bySubClassNameAndSummaryType[sub_class_name]['total'] += cost;
                    bySubClassNameAndSummaryType[sub_class_name]['values'][summary_type] += cost;
                });

                // GRAPH BY SUMMARY TYPE
                const bySummaryTypeData = this._cleanDataForGraph(
                    bySummaryType, this.legend, true);
                this.updateChart(
                    this.renewalDoughnut,
                    bySummaryTypeData[0],
                    [{
                        data: bySummaryTypeData[1],
                        backgroundColor: bySummaryTypeData[2],
                        label: '1',
                    }]);


                // GRAPH BY SUBCLASS AND SUMMARY TYPE
                let labels = [];
                let datasets = [];
                let keys = Object.keys(bySubClassNameAndSummaryType).sort();
                let byClassIndexSum = {};
                keys.forEach(function (key, byClassIndex) {
                    const data = bySubClassNameAndSummaryType[key];
                    const total = data['total'];
                    const values = data['values'];
                    labels.push(key);

                    // check all data by legend
                    let legends = Object.keys(that.legend);
                    legends.forEach(function (legend, byLegendIndex) {
                        const color = that.legend[legend];
                        if (!datasets[byLegendIndex]) {
                            datasets[byLegendIndex] = {
                                label: legend,
                                data: [],
                                labels: [],
                                backgroundColor: color
                            }
                        }
                        const value = values[legend] ? values[legend] : 0;
                        datasets[byLegendIndex]['data'][byClassIndex] = ((value / total).toFixed(3)) * 100;
                        if (isNaN(datasets[byLegendIndex]['data'][byClassIndex])) {
                            datasets[byLegendIndex]['data'][byClassIndex] = 0;
                        }

                        // we need to make sure the data is 100
                        if (!byClassIndexSum[byClassIndex]) {
                            byClassIndexSum[byClassIndex] = 0;
                        }
                        byClassIndexSum[byClassIndex] += datasets[byLegendIndex]['data'][byClassIndex];
                        if (byClassIndexSum[byClassIndex] > 100) {
                            const excess = byClassIndexSum[byClassIndex] - 100;
                            datasets[byLegendIndex]['data'][byClassIndex] = datasets[byLegendIndex]['data'][byClassIndex] - excess;
                            if (datasets[byLegendIndex]['data'][byClassIndex] < 0) {
                                datasets[byLegendIndex]['data'][byClassIndex] = 0
                            }
                        }
                        datasets[byLegendIndex]['labels'][byClassIndex] =
                            `${numberWithCommas(value)} (${datasets[byLegendIndex]['data'][byClassIndex].toFixed(1)}%)`
                    });
                });
                this.updateChart(
                    this.renewalBar, labels, datasets);
            }
        },
        /** Initiate chart into variable
         */
        initChart: function ($canvas, type, isBar) {
            const that = this;
            let legend = {};
            let scales = {};
            if (isBar) {
                legend = {
                    display: false,
                    labels: {
                        display: false
                    }
                };
                scales = {
                    x: {
                        stacked: true,
                        ticks: {
                            autoSkip: false,
                            maxRotation: 90,
                            minRotation: 90
                        }

                    },
                    y: {
                        stacked: true,
                        ticks: {
                            display: false
                        }
                    }
                }
            }
            return new Chart(
                $canvas[0].getContext('2d'), {
                    type: type,
                    data: {
                        labels: [],
                        datasets: []
                    },
                    options: {
                        responsive: true,
                        hover: {
                            onHover: function (e) {
                                var point = this.getElementAtEvent(e);
                                if (point.length) e.target.style.cursor = 'pointer';
                                else e.target.style.cursor = 'default';
                            }
                        },
                        scales: scales,
                        plugins: {
                            legend: legend,
                            tooltip: {
                                callbacks: {
                                    label: function (t, d) {
                                        if (t.dataset['labels']) {
                                            let label = t.dataset['labels'][t.dataIndex];
                                            try {
                                                const value = parseFloat(label.split(' (')[0].replaceAll(',', ''));
                                                label = that.community.get('currencyFormatter').format(value) + ` (${t.formattedValue}%)`
                                            } catch (e) {

                                            }
                                            return ' ' + t.dataset['label'] + ': ' + label;
                                        } else {
                                            if (type === 'doughnut') {
                                                let sum = 0;
                                                t.dataset['data'].map(data => {
                                                    sum += data;
                                                });
                                                return that.community.get('currencyFormatter').format(t.raw) + ` (${(t.raw * 100 / sum).toFixed(2) + "%"})`;
                                            }
                                            return ' ' + that.community.get('currencyFormatter').format(t.raw);
                                        }
                                    }
                                }
                            },
                        }
                    }
                });
        },

        /***
         * Update chart for the new data
         */
        updateChart: function (chart, labels, datasets) {
            chart.data = {
                labels: labels,
                datasets: datasets
            };
            chart.update()
        },
        _cleanDataForGraph: function (data, legend, keyUsingLegend) {
            let labels = [];
            let values = [];
            let backgroundColours = [];
            let keys = Object.keys(data).sort();
            if (keyUsingLegend) {
                keys = Object.keys(legend);
            }
            keys.forEach(function (key) {
                const value = data[key];
                if (value) {
                    labels.push(key);
                    values.push(value);

                    // color
                    if (!legend[key]) {
                        legend[key] = getRandomColor();
                    }
                    backgroundColours.push(legend[key]);
                }
            });
            return [labels, values, backgroundColours];
        },
        /** When community changed
         * Change the data to the community
         * @param community
         */
        communityChanged(community) {
            this.community = community;
            this.rerender();
        },
        /** When classes that active changed
         * Filter the data to the classes
         * @param classes
         */
        classesChanged(classes) {
            this.classes = classes;
            this.rerender();
        },
    });
});