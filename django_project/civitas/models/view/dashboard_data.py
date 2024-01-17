from collections import defaultdict
from decimal import Decimal
from itertools import groupby
import operator
import pprint

class DashboardData():

    def __init__(self, data):
        self.data = data

        self.risk_level_list = [
            {"risk_level":"Extreme", "index": 5}, 
            {"risk_level":"High" , "index": 4}, 
            {"risk_level":"Medium" , "index": 3}, 
            {"risk_level":"Low", "index": 2}, 
            {"risk_level":"Minimal", "index": 1}, 
            {"risk_level":"None", "index": 0}
        ]
        
    def stacked_a(self, risk_renewal_of_assets):
        """risk_renewal_assets_list

        Returns:
            formatted list to be used correctly in table
        """
        risk_renewal_formatted_list = []
        total_sum = 0
        for k in list(risk_renewal_of_assets):
            if k["values"] is not None:
                values = k["values"]
            else:
                values = 0

            if k not in risk_renewal_formatted_list:
                risk_renewal_formatted_list\
                    .append({
                        'system_name': k["system_name"], 
                        "risk": [], 
                        "total_value": 0, 
                        "total_per": 0
                    })
                total_sum = float(total_sum) + float(values)

        final_risk_renewal = [i for j, i in enumerate(risk_renewal_formatted_list) if i not in risk_renewal_formatted_list[:j]]

        for val in list(risk_renewal_of_assets):
            for key in final_risk_renewal:
                if key['system_name'] == val["system_name"]:
                    value = val['risk_level']

                    if str(val["values"] ) == "NaN" or str(val["values"] ) == "nan":
                        _values = 0

                    elif val["values"] is not None:
                        _values = val["values"]
                    
                    else:
                        _values = 0

                    key["risk"].append({"risk_level": value, "values": _values})
                    key["total_value"] = float(key["total_value"]) + float(_values)
                    key["total_per"] = (float(key["total_value"] ) / total_sum) * 100
        
        return final_risk_renewal
    
    def stacked_a_total(self, input_list):
        formatted_list = []
        for val in self.risk_level_list:
            formatted_list.append({
                'risk_level': val["risk_level"], 
                'total': 0
            })

        for val in input_list:
            for risk in val['risk']:

                index = [i for i,_ in enumerate(formatted_list) if _['risk_level'] == risk['risk_level']][0]
                formatted_list[index]['total'] = formatted_list[index]['total'] + risk['values']
                    
        return formatted_list
    
    def stacked_b_list(self, system_names):
        """remaining_years_renewal_system

        Returns:
            formatted list to be used correctly in table and graph
        """

        # find lowest value
        # lowest = (min(data, key=lambda x:x['remaining_years']))

        # create interval of 5 years
        remaining_years_formatted_list = []
        for x in range(95, -6, -5):
            remaining_years_formatted_list.append({
                'remaining_years': f"{x} - {x+4}", 
                'asset': [], 
                'total': 0
            })

        # append data to list for interval
        for k in self.data:
            for val in remaining_years_formatted_list:
                str_split = val["remaining_years"].split(" - ")
                min = int(str_split[0])
                max = int(str_split[1])
                if k.remaining_years is not None:
                    remaining_years = k.remaining_years 
                else:
                    remaining_years = 0
                
                if min <= remaining_years <= max:
                    if min <= remaining_years <= max:

                        if str(k.renewal_cost) == "NaN":
                            renewal_cost = 0
                        
                        elif k.renewal_cost is not None :
                            renewal_cost = k.renewal_cost
                        else:
                            renewal_cost = 0

                        if not any(d['system_name'] == k.system_name for d in val['asset']):
                            val["asset"]\
                            .append({
                                'system_name': k.system_name, 
                                'values': renewal_cost
                            })
                            val['total'] = val['total'] + renewal_cost
                        else:
                            index = [i for i,_ in enumerate(val['asset']) if _['system_name'] == k.system_name][0]
                            val['asset'][index]['values'] = val['asset'][index]['values'] + renewal_cost
                            val['total'] = val['total'] + renewal_cost

        # add system names where value is 0 for graph to work correctly
        for k in remaining_years_formatted_list:
            for system in system_names:
                if not any(d['system_name'] == system["system_name"] for d in k["asset"]):
                    k["asset"]\
                        .append({
                            'system_name': system["system_name"], 
                            'values': 0.00
                        })

        # sort list alphabetically
        for k in remaining_years_formatted_list:
            new_list = sorted(k['asset'], key=operator.itemgetter('system_name'))     
            k['asset'] = new_list

        return reversed(remaining_years_formatted_list)
    
    def stacked_b_total(self, input_list, system_names):
        formatted_list = []  
        for system in system_names:
            formatted_list\
                .append({
                    'name': system["system_name"], 
                    'total': 0
                })

        for input in input_list:
            for list in formatted_list:
                for asset in input['asset']:
                    if list['name'] == asset['system_name']:
                        list['total'] = float(list['total']) + float(asset['values'])

        return formatted_list
    
    def stacked_b_graph(self, input_list, system_names):
        """remaining_years_renewal_system

        Returns:
            formatted list to be used correctly in graph
        """
        formatted_list = []   

        # start with basic list
        for system in system_names:
            formatted_list\
                .append({'name': system["system_name"], 
                                   'type': 'bar', 
                                   'x': [], 
                                   'y': []}
                                )

        for input in input_list:
            for list in formatted_list:
                for asset in input['asset']:
                    if list['name'] == asset['system_name']:
                        list["x"].append(input["remaining_years"])
                        if isinstance(asset["values"], float) or isinstance(asset["values"], Decimal):
                            list["y"].append(float(asset["values"]))

        return formatted_list

    def stacked_c_list(self):
            """remaining_years_renewal_system

            Returns:
                formatted list to be used correctly in table and graph
            """
            # create interval of 5 years
            remaining_years_formatted_list = []
            for x in range(95, -6, -5):
                remaining_years_formatted_list.append({
                    'remaining_years': f"{x} - {x+4}", 
                    'risk_level': [], 
                    'total': 0
                })

            # append data to list for interval
            for k in self.data:
                for val in remaining_years_formatted_list:
                    str_split = val["remaining_years"].split(" - ")
                    min = int(str_split[0])
                    max = int(str_split[1])
                    
                    if k.remaining_years is not None:
                        remaining_years = k.remaining_years 
                    else:
                        remaining_years = 0
                    
                    if min <= remaining_years <= max:
                        if k.risk_level is None:
                                risk_lev = "None"
                        else:
                            risk_lev = k.risk_level.strip()

                        risk_level_index = [i for i,_ in enumerate(self.risk_level_list) if _['risk_level'] == risk_lev][0]

                        if not any(d['level'] == risk_lev for d in val['risk_level']):
                            if str(k.renewal_cost) == 'NaN':
                                val['total'] = float(0.00)
                                val["risk_level"]\
                                .append({'level': risk_lev, 
                                        'values': 0.00, 
                                        'index': 0
                                        })
                            if k.renewal_cost is not None:
                                val["risk_level"]\
                                    .append({
                                        'level': risk_lev, 
                                        'values': k.renewal_cost, 
                                        'index': self.risk_level_list[risk_level_index]['index']
                                    })
                                val['total'] = float(val['total']) + float(k.renewal_cost)
                            else: 
                                val['total'] = float(0.00)
                                val["risk_level"]\
                                .append({'level': risk_lev, 
                                        'values': 0.00, 
                                        'index': 0
                                        })
                        else:
                            index = [i for i,_ in enumerate(val['risk_level']) if _['level'] == risk_lev][0]
                            if str(k.renewal_cost) == 'NaN':
                                val['risk_level'][index]['values'] = float(val['risk_level'][index]['values']) + float(0)
                                val['total'] = float(val['total']) + float(0)
                            elif k.renewal_cost is not None:
                                val['risk_level'][index]['values'] = float(val['risk_level'][index]['values']) + float(k.renewal_cost)
                                val['total'] = float(val['total']) + float(k.renewal_cost)

            # add system names where value is 0 for graph to work correctly
            for k in remaining_years_formatted_list:
                for lev in self.risk_level_list:
                    if not any(d['level'] == lev["risk_level"] for d in k["risk_level"]):
                        risk_level_index = [i for i,_ in enumerate(self.risk_level_list) if _['risk_level'] == lev["risk_level"]][0]
                        k["risk_level"]\
                            .append({
                                'level': lev["risk_level"], 
                                'values': 0.00, 
                                'index': self.risk_level_list[risk_level_index]['index']
                            })

            # sort list from highest to lowest
            for k in remaining_years_formatted_list:
                new_list = sorted(k['risk_level'], key=operator.itemgetter('index'))     
                k['risk_level'] = reversed(new_list)
 
            return reversed(remaining_years_formatted_list)
        
    def stacked_c_total(self, input_list):
        formatted_list = []  
        for risk in self.risk_level_list:
            formatted_list\
                .append({
                    'name': risk["risk_level"], 
                    'total': 0
                })
        
        for input in input_list:
            for val in input["risk_level"]:
                for item in formatted_list:
                    if val['level'] == item['name']:
                        item['total'] = float(item['total']) + float(val['values'])

        return formatted_list
    
    def stacked_c_graph(self, input_list):
        """remaining_years_renewal_system

        Returns:
            formatted list to be used correctly in graph
        """
        formatted_list = []   

        # start with basic list
        for risk in self.risk_level_list:
            formatted_list\
                .append({
                    'name': risk["risk_level"], 
                    'type': 'bar', 'x': [], 'y': []
                })

        for input in input_list:
            for asset in input['risk_level']:
                for list in formatted_list:
                
                    if list['name'] == asset['level']:
                        list["x"].append(input["remaining_years"])
                        list["y"].append(asset["values"])

        return formatted_list
    
    def pdf_table_1(self, input_list):
        formatted_list = []
        new_list = list(input_list)
        # print("\n Val")
        # pprint.pprint(list(new_list))

        for val in new_list:
            remaining_years = val["remaining_years"].split(' - ')
            if int(remaining_years[1]) <= 64:
                formatted_list.append(val)
        
        # print("\n Val")
        # pprint.pprint(list(formatted_list))

        return formatted_list
    
    def pdf_table_2(self, input_list):
        formatted_list = []
        new_list = list(input_list)
        # print("\n Val")
        # pprint.pprint(list(new_list))

        for val in new_list:
            remaining_years = val["remaining_years"].split(' - ')
            if int(remaining_years[1]) > 64:
                formatted_list.append(val)
        
        print("\n Val")
        pprint.pprint(list(formatted_list))

        return formatted_list

    
    
    
    
