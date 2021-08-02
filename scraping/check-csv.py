#!/usr/bin/env python3

import sys
import re

# スクレイピングしたデータ
f = open('stations-scrapped.csv', 'r', encoding='utf-8')
buf = f.readlines()

# 駅名 をキーにした map、緯度経度をキーにした map を作成
map={}
map_latlng={}
for line in buf:
    line = str(line).strip()
    arr = line.split(',')
    station_name = arr[1]
    latlng = arr[3]+","+arr[4]
    map[station_name] = arr
    map_latlng[latlng] = arr


# 駅メモマップ2 のデータ

# 駅コード→都道府県名 code2pref 生成
code2pref={}
f2 = open('../static/map/data/station_pref.csv', encoding='utf-8')
buf = f2.readlines()
for line in buf:
    line = str(line).strip()
    arr = line.split(',')
    code=arr[0]
    pref=re.sub('(都|府|県)$', '', arr[3])
    code2pref[code]=pref

f = open('../static/map/data/stations.csv', 'r', encoding='utf-8')
buf = f.readlines()
map2={}
buf.pop(0)


# 駅名 をキーにした map を作成
for line in buf:
    line = str(line).strip()
    arr = line.split(',')
    station_name = arr[1]
#    print(station_name)
    if station_name in map2:
        map2[station_name].append(arr)
    else:
        map2[station_name] = [arr]

map_to_map2 = {}

for station_name in map2.keys():
#    print("CHECK "+station_name)
    for arr in map2[station_name]:
        code=arr[0]
        latlng=arr[2]+","+arr[3]

        if code in code2pref:
            pref=code2pref[code]
        else:
            pref=""

        correct_station_name = ''
        if station_name in map:
            correct_station_name = station_name

        elif station_name.replace('ケ','ヶ') in map:
            correct_station_name = station_name.replace('ケ','ヶ')

        elif station_name.replace('ヶ','ケ') in map:
            correct_station_name = station_name.replace('ヶ','ケ')
    
        elif station_name.replace('（','(').replace('）',')') in map:
            correct_station_name = station_name.replace('（','(').replace('）',')')

        elif station_name+"("+pref+")" in map:
            correct_station_name = station_name+"("+pref+")"

        elif latlng in map_latlng:
            correct_station_name = map_latlng[latlng][1]
        else:
            print("駅メモマップ2にしかない駅: "+station_name)

        if correct_station_name != '' and correct_station_name != station_name:
            pass
#            print(station_name+" → "+correct_station_name)
        print("{},{},{},{}".format(code, correct_station_name, map[correct_station_name][5], map[correct_station_name][6]))
        map_to_map2[correct_station_name] = 1

for station_name in map.keys():
    if station_name in map_to_map2:
#        print("OK "+station_name)
        pass
    else:
        print("駅メモにしかない駅 "+station_name)
