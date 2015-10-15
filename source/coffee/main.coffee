checkedList = []

main = (stations) ->
  initMap = (lat, lng) ->
    polygons = markers = []

    map = new (google.maps.Map)(document.getElementById('map'),
      zoom: 13
      center: new (google.maps.LatLng)(lat, lng)
      mapTypeId: google.maps.MapTypeId.ROADMAP
      disableDoubleClickZoom: true)

    do ->
      set = google.maps.InfoWindow::set
      google.maps.InfoWindow::set = (k, v) ->
        if k == 'map'
          if !@get('noSupress')
            return
        set.apply this, arguments

    google.maps.Map.prototype.clearOverlays = ->
      polygons.forEach (v) ->
        v.setMap null
      markers.forEach (v) ->
        v.setMap null

    google.maps.event.addListener map, 'idle', ->
      map.clearOverlays()

      bufferRange = 0.5
      bounds = map.getBounds()
      stationsFilter = stations.filter((v) ->
        v.lat > bounds.getSouthWest().lat() - bufferRange and v.lat < bounds.getNorthEast().lat() + bufferRange and v.lng > bounds.getSouthWest().lng() - bufferRange and v.lng < bounds.getNorthEast().lng() + bufferRange
      )

      voronois = d3.geom.voronoi(stationsFilter.map (v) -> [v.lat, v.lng])

      stationsFilter.forEach (d, i) ->
        paths = voronois[i].map (v) ->
          new (google.maps.LatLng)(v[0], v[1])

        if checkedList.indexOf(d.cd) != -1
          fillColor = '#f00'
        else
          fillColor = 'transparent'

        polygon = new google.maps.Polygon
          paths: paths
          strokeColor: '#f00'
          strokeOpacity: .4
          strokeWeight: 2
          fillColor: fillColor
          fillOpacity: .2

        google.maps.event.addListener polygon, 'mouseover', ->
          @setOptions
            fillOpacity: .4
        google.maps.event.addListener polygon, 'mouseout', ->
          @setOptions
            fillOpacity: .2
        google.maps.event.addListener polygon, 'dblclick', ->
          if checkedList.indexOf(d.cd) != -1
            checkedList = checkedList.filter((v) ->
              v != d.cd
            )
            @setOptions
              fillColor: 'transparent'
          else
            checkedList.push d.cd
            @setOptions
              fillColor: '#f00'

          localStorage.setItem 'ekimemo_checkedList', JSON.stringify(checkedList)

        polygon.setMap map
        polygons.push polygon

        if map.getZoom() >= 10
          markers.push new google.maps.Marker
            position: new (google.maps.LatLng)(d.lat, d.lng)
            map: map
            label: d.name
            title: d.name

  if location.hash and matches = location.hash.match /#([+-]?[\d\.]+),([+-]?[\d\.]+)/
    initMap matches[1], matches[2]
  else if navigator.geolocation
    navigator.geolocation.getCurrentPosition (position) ->
      initMap position.coords.latitude, position.coords.lnggitude
  else
    initMap 35.659, 139.745

if localStorage.getItem('ekimemo_checkedList')
  try
    checkedList = JSON.parse(localStorage.getItem('ekimemo_checkedList'))
  catch e
    console.log e
    checkedList = []
d3.csv './data/stations.csv', (stations) ->
  main stations
