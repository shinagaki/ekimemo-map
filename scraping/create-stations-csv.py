#!/usr/bin/env python3

import pathlib
import glob
import re

prefs = {
'01':'北海道',
'02':'青森県',
'03':'岩手県',
'04':'宮城県',
'05':'秋田県',
'06':'山形県',
'07':'福島県',
'08':'茨城県',
'09':'栃木県',
'10':'群馬県',
'11':'埼玉県',
'12':'千葉県',
'13':'東京都',
'14':'神奈川県',
'15':'新潟県',
'16':'富山県',
'17':'石川県',
'18':'福井県',
'19':'山梨県',
'20':'長野県',
'21':'岐阜県',
'22':'静岡県',
'23':'愛知県',
'24':'三重県',
'25':'滋賀県',
'26':'京都府',
'27':'大阪府',
'28':'兵庫県',
'29':'奈良県',
'30':'和歌山県',
'31':'鳥取県',
'32':'島根県',
'33':'岡山県',
'34':'広島県',
'35':'山口県',
'36':'徳島県',
'37':'香川県',
'38':'愛媛県',
'39':'高知県',
'40':'福岡県',
'41':'佐賀県',
'42':'長崎県',
'43':'熊本県',
'44':'大分県',
'45':'宮崎県',
'46':'鹿児島県',
'47':'沖縄県',
}

prefname2code = {}
for code,name in prefs.items():
    prefname2code[name]=code


out = open("stations-scrapped.csv", mode="w")

for file in list(pathlib.Path('station/').glob('s*.html')):
    cd = None
    m = re.search(r's([0-9]+).html', str(file))
    if m:
        cd = m[1]
            
    with open(file, 'r', encoding='utf-8') as f:
        pref = None
        name = None
        kana = None
        lat = None
        lng = None

        y = f.read()
#        print(y)
        m = re.search(r'<div class="pref">(.*?)</div>', y)
        if ( m ):
            pref = m[1]
        m = re.search(r'<div class="name">(.*?)</div>', y)
        if ( m ):
            name = m[1]
        m = re.search(r'<div class="kana">(.*?)</div>', y)
        if ( m ):
            kana = m[1]
        m = re.search(r'lat="(.*?)"', y)
        if ( m ):
            lat = m[1]
        m = re.search(r'lng="(.*?)"', y)
        if ( m ):
            lng = m[1]

        out.write("{},{},{},{},{},{},{}\n".format(cd, name, kana, lat, lng, prefname2code[pref], pref))

        if cd is None or name is None or kana is None or lat is None or lng is None or pref is None or not pref in prefname2code:
            print("BAD!")
            last

#            <div class="pref">北海道</div>
#            <div class="name">大沼</div>
#            <div class="kana">おおぬま</div>
#            lat="41.971954"
#            lng="140.669347"
    
out.close()
