var DISPLAY_MARKER_THRESHOLD, MAP_CENTER_DEFAULT, checkedList, geocoder, main, map;

MAP_CENTER_DEFAULT = {
  lat: 35.659,
  lng: 139.745
};

DISPLAY_MARKER_THRESHOLD = 6;

// 取済済駅色
checkedFillColor = '#f00';
// 取済済廃駅色
checkedAbandonedFillColor = '#888';

checkedList = [];

geocoder = null;

map = null;

main = function(stations) {
  var changedHash, initMap;
  initMap = function(lat, lng, zoom) {
    var addRaderMarker, currentLatLng, currentZoom, enableMarker, enablePolygon, iconList, markers, polygons, raderCenter, raderMarkers, redraw, stationsFilter, useRader;
    if (lat == null) {
      lat = MAP_CENTER_DEFAULT.lat;
    }
    if (lng == null) {
      lng = MAP_CENTER_DEFAULT.lng;
    }
    if (zoom == null) {
      zoom = 13;
    }
    polygons = [];
    markers = [];
    raderMarkers = [];
    stationsFilter = null;
    currentLatLng = null;
    currentZoom = null;
    enablePolygon = true;
    enableMarker = true;
    iconList = {
      sphereRed: new google.maps.MarkerImage('images/icon-sphere_red.png', new google.maps.Size(8, 8), new google.maps.Point(0, 0), new google.maps.Point(4, 4)),
      sphereGray: new google.maps.MarkerImage('images/icon-sphere_gray.png', new google.maps.Size(8, 8), new google.maps.Point(0, 0), new google.maps.Point(4, 4)),
      raderCenter: new google.maps.MarkerImage('http://www.google.com/mapfiles/gadget/arrowSmall80.png', new google.maps.Size(31, 27), new google.maps.Point(0, 0), new google.maps.Point(9, 27))
    };
    map = new google.maps.Map(document.getElementById('map'), {
      zoom: zoom,
      center: new google.maps.LatLng(lat, lng),
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      streetViewControl: false,
      disableDoubleClickZoom: true
    });
    (function() {
      var set;
      set = google.maps.InfoWindow.prototype.set;
      return google.maps.InfoWindow.prototype.set = function(k, v) {
        if (k === 'map') {
          if (!this.get('noSupress')) {
            return;
          }
        }
        return set.apply(this, arguments);
      };
    })();
    google.maps.Map.prototype.clearOverlays = function() {
      polygons.forEach(function(v) {
        return v.setMap(null);
      });
      if (!enableMarker || currentZoom < DISPLAY_MARKER_THRESHOLD) {
        return markers.forEach(function(v) {
          return v.setMap(null);
        });
      }
    };
    redraw = function(force) {
      var bounds, bufferRange, newLatLng, newZoom, voronoi, voronois;
      if (force == null) {
        force = false;
      }
      newLatLng = map.getCenter();
      newZoom = map.getZoom();
      if (!force && currentLatLng && Math.abs(currentLatLng.lat() - newLatLng.lat()) < 0.2 && Math.abs(currentLatLng.lng() - newLatLng.lng()) < 0.2 && currentZoom && currentZoom === newZoom) {
        return;
      }
      currentLatLng = newLatLng;
      currentZoom = newZoom;
      map.clearOverlays();
      bufferRange = 0.5;
      bounds = map.getBounds();
      document.getElementById('all_stations_num').textContent = stations.length;
      document.getElementById('checked_stations_num').textContent = checkedList.length;
      document.getElementById('checked_percentage').textContent = Math.trunc(checkedList.length / stations.length*10000)/100;

      let tmp = stations.filter(function(v) {
        let abandoned_mode = Number(document.getElementById('abandoned_mode').value);

        if ( abandoned_mode===0 ){
	  // 現行駅・廃駅両方表示
	  return true;
	}
	if ( abandoned_mode===1 ){
	  // 廃駅のみ
	  return v.type === "2";
	}
	if ( abandoned_mode===2 ){
	  // 現行駅のみ
	  return v.type === "1";
	}
      });
      stationsFilter = tmp.filter(function(v) {
          return v.lat > bounds.getSouthWest().lat() - bufferRange
	      && v.lat < bounds.getNorthEast().lat() + bufferRange
	      && v.lng > bounds.getSouthWest().lng() - bufferRange
	      && v.lng < bounds.getNorthEast().lng() + bufferRange;
      });
      if (enablePolygon) {
        voronoi = d3.geom.voronoi().clipExtent([[0, 110], [60, 170]]);
        voronois = voronoi(stationsFilter.map(function(v) {
          return [v.lat, v.lng];
        }));
      }


      return stationsFilter.forEach(function(d, i) {
        var fillColor, icon, marker, paths, polygon, strokeWeight;
        if (enablePolygon) {
          paths = voronois[i].map(function(v) {
            if (Object.keys(v !== 'point')) {
              return new google.maps.LatLng(v[0], v[1]);
            }
          });
          if (checkedList.indexOf(d.cd) !== -1) {
            fillColor = +d.type===1 ? checkedFillColor : checkedAbandonedFillColor; // 取得済みポリゴン塗りつぶし色 (初期表示)
          } else {
            fillColor = 'transparent';
          }
          if (currentZoom >= DISPLAY_MARKER_THRESHOLD) {
            strokeWeight = 1;
          } else {
            strokeWeight = 1;
          }
          polygon = new google.maps.Polygon({
            paths: paths,
            strokeColor: '#f00', // ポリゴン枠線
            strokeOpacity: .3, // ポリゴン枠線不透明度
            strokeWeight: strokeWeight,
            fillColor: fillColor,
            fillOpacity: .2 // 塗りつぶし不透明度
          });

	  // ダブルクリック時のトグル動作
          google.maps.event.addListener(polygon, 'dblclick', function() {
            if (checkedList.indexOf(d.cd) !== -1) {
              checkedList = checkedList.filter(function(v) {
                return v !== d.cd;
              });
              this.setOptions({
                fillColor: 'transparent'
              });
            } else {
              checkedList.push(d.cd);
              this.setOptions({
                  fillColor: +d.type===1 ? checkedFillColor : checkedAbandonedFillColor // 取得済み駅塗りつぶし (ダブルクリック時)
              });
            }
            return localStorage.setItem('ekimemo_checkedList', JSON.stringify(checkedList));
          });

          polygon.setMap(map);
          polygons.push(polygon);
        }
        if (enableMarker && currentZoom >= DISPLAY_MARKER_THRESHOLD) {
          if (!markers[d.cd]) {
            if (+d.type === 2) {
              icon = iconList.sphereGray;
            } else {
              icon = iconList.sphereRed;
            }
            if (checkedList.indexOf(d.cd) === -1) {
              marker = new google.maps.Marker({
                position: new google.maps.LatLng(d.lat, d.lng),
                map: map,
                icon: icon,
                title: d.name
              });
            }
            return markers[d.cd] = marker;
          }
        }
      });
    };
    addRaderMarker = function(latLng, dist, i) {
      var bgColor;
      bgColor = (255 - i * 15).toString(16) + (220 - i * 8).toString(16) + '66';
      return raderMarkers.push(new google.maps.Marker({
        position: latLng,
        map: map,
        icon: 'http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=' + (i + 1) + '|' + bgColor + '|000000',
        animation: google.maps.Animation.DROP,
        clickable: false
      }));
    };
    raderCenter = new google.maps.Marker({
      icon: iconList.raderCenter,
      animation: google.maps.Animation.DROP,
      draggable: true
    });
    useRader = function(latLng) {
      var d, distances, i, j, len, ref, results1;
      distances = [];
      stationsFilter.forEach(function(d, i) {
        var stationLatLng;
        stationLatLng = new google.maps.LatLng(d.lat, d.lng);
        return distances.push({
          dist: Math.sqrt(Math.pow(Math.abs(d.lat - latLng.lat()), 2) + Math.pow(Math.abs(d.lng - latLng.lng()), 2)),
          cd: d.cd,
          latLng: stationLatLng
        });
      });
      distances.sort(function(a, b) {
        return d3.ascending(a.dist, b.dist);
      });
      raderMarkers.forEach(function(v) {
        return v.setMap(null);
      });
      raderMarkers = [];
      ref = distances.slice(0, 14);
      results1 = [];
      for (i = j = 0, len = ref.length; j < len; i = ++j) {
        d = ref[i];
        results1.push(setTimeout(function(d, i) {
          return addRaderMarker(d.latLng, d.dist, i);
        }, i * 150, d, i));
      }
      return results1;
    };
    // 廃駅モード切り替え
      document.getElementById("abandoned_label").onclick = function(event){
        let labels = ['含む','のみ','除く'];
	let e = document.getElementById("abandoned_mode");
	let next_abandoned_mode = (Number(e.value)+1)%3;
	e.value = next_abandoned_mode;
        event.target.innerText = labels[next_abandoned_mode];
	  return init();
    };
    google.maps.event.addListener(raderCenter, 'dragend', function(e) {
      return useRader(e.latLng);
    });
    google.maps.event.addListener(map, 'idle', function() {
      return redraw();
    });
    if (!localStorage.getItem('ekimemo_updated') || $("#modal .update-date").data('updated') > localStorage.getItem('ekimemo_updated')) {
      localStorage.setItem('ekimemo_updated', $("#modal .update-date").data('updated'));
      $("#modal").openModal();
    }
    // ポリゴンボタンクリック (トグル)
    $(".js-btn-polygon").on('click', function() {
      if ($(this).hasClass('disabled')) {
        $(this).removeClass('disabled');
        $(this).addClass('teal');
        enablePolygon = true;
      } else {
        $(this).removeClass('teal');
        $(this).addClass('disabled');
        enablePolygon = false;
      }
      $(".fixed-action-btn").removeClass('active');
      return redraw(true);
    });
    // マーカーボタンクリック (トグル)
    $(".js-btn-marker").on('click', function() {
      if ($(this).hasClass('disabled')) {
        $(this).removeClass('disabled');
        $(this).addClass('cyan');
        enableMarker = true;
      } else {
        $(this).removeClass('cyan');
        $(this).addClass('disabled');
        enableMarker = false;
      }
      $(".fixed-action-btn").removeClass('active');
      return redraw(true);
    });
    // レーダーボタンクリック
    $(".js-btn-rader").on('click', function() {
      if ($(this).hasClass('disabled')) {
        $(this).removeClass('disabled');
        $(this).addClass('light-blue');
        raderCenter.setPosition(map.getCenter());
        useRader(map.getCenter());
        raderCenter.setMap(map);
      } else {
        $(this).removeClass('light-blue');
        $(this).addClass('disabled');
        raderMarkers.forEach(function(v) {
          return v.setMap(null);
        });
        raderCenter.setMap(null);
      }
      return $(".fixed-action-btn").removeClass('active');
    });
    return $(window).on('hashchange', function() {
      return changedHash();
    });
  };
  changedHash = function() {
    var matches;
    if (matches = location.hash.match(/#([+-]?[\d\.]+),([+-]?[\d\.]+)/)) {
      return initMap(matches[1], matches[2]);
    } else {
      if (!geocoder) {
        geocoder = new google.maps.Geocoder();
      }
      return geocoder.geocode({
        address: location.hash.substr(1)
      }, function(results, status) {
        if (status === google.maps.GeocoderStatus.OK) {
          if (map) {
            return map.setCenter(results[0].geometry.location);
          } else {
            return initMap(results[0].geometry.location.lat(), results[0].geometry.location.lng());
          }
        } else {
          if (!map) {
            return initMap();
          }
        }
      });
    }
  };
  if (location.hash) {
    return changedHash();
  } else if (navigator.geolocation) {
    return navigator.geolocation.getCurrentPosition(function(position) {
      if (position != null ? position.coords : void 0) {
        return initMap(position.coords.latitude, position.coords.longitude);
      } else {
        return initMap();
      }
    }, function() {
      return initMap();
    });
  } else {
    return initMap();
  }
};

function init(){
  var e;
  if (localStorage.getItem('ekimemo_checkedList')) {
    try {
      checkedList = JSON.parse(localStorage.getItem('ekimemo_checkedList'));
    } catch (error) {
      e = error;
      console.log(e);
      checkedList = [];
    }
  }
  return d3.csv('./data/stations.csv?dxxx', function(stations) {
    return main(stations);
  });
}

$(function() {
    init();
});
