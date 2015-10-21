MAP_CENTER_DEFAULT =
  lat: 35.659
  lng: 139.745
DISPLAY_MARKER_THRESHOLD = 11

checkedList = []

main = (stations) ->
  initMap = (lat = MAP_CENTER_DEFAULT.lat, lng = MAP_CENTER_DEFAULT.lng, zoom = 13) ->
    polygons = []
    markers = []
    iconList = 
      sphereRed: new google.maps.MarkerImage 'images/icon-sphere_red.png', new google.maps.Size(8, 8), new google.maps.Point(0, 0), new google.maps.Point(4, 4)
      sphereGray: new google.maps.MarkerImage 'images/icon-sphere_gray.png', new google.maps.Size(8, 8), new google.maps.Point(0, 0), new google.maps.Point(4, 4)

    map = new (google.maps.Map)(document.getElementById('map'),
      zoom: zoom
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

      if map.getZoom() < DISPLAY_MARKER_THRESHOLD
        markers.forEach (v) ->
          v.setMap null

    google.maps.event.addListener map, 'idle', ->
      map.clearOverlays()

      bufferRange = 0.5
      bounds = map.getBounds()
      stationsFilter = stations.filter((v) ->
        v.lat > bounds.getSouthWest().lat() - bufferRange and v.lat < bounds.getNorthEast().lat() + bufferRange and v.lng > bounds.getSouthWest().lng() - bufferRange and v.lng < bounds.getNorthEast().lng() + bufferRange
      )

      voronoi = d3.geom.voronoi().clipExtent([[0, 110], [60, 170]])
      # voronoi = d3.geom.voronoi()
      voronois = voronoi(stationsFilter.map (v) -> [v.lat, v.lng])

      stationsFilter.forEach (d, i) ->
        paths = voronois[i].map (v) ->
          if Object.keys v != 'point'
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

        if map.getZoom() >= DISPLAY_MARKER_THRESHOLD
          if !markers[d.cd]
            if +d.type == 2
              icon = iconList.sphereGray
            else
              icon = iconList.sphereRed

            marker = new MarkerWithLabel
              position: new (google.maps.LatLng)(d.lat, d.lng)
              map: map
              labelContent: d.name
              labelAnchor: new google.maps.Point(-5, 9)
              labelClass: 'labels'
              icon: icon
            markers[d.cd] = marker
          else if markers[d.cd].getMap() == null
            markers[d.cd].setMap map

  if location.hash and matches = location.hash.match /#([+-]?[\d\.]+),([+-]?[\d\.]+)/
    initMap matches[1], matches[2]
  else if navigator.geolocation

    console.log navigator.geolocation
    navigator.geolocation.getCurrentPosition (position) ->
      if position?.coords
        initMap position.coords.latitude, position.coords.longitude
      else
        initMap()
    , ->
      initMap()
  else
    initMap()

if localStorage.getItem('ekimemo_checkedList')
  try
    checkedList = JSON.parse(localStorage.getItem('ekimemo_checkedList'))
  catch e
    console.log e
    checkedList = []
d3.csv './data/stations.csv', (stations) ->
  main stations
