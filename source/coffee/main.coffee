MAP_CENTER_DEFAULT =
  lat: 35.659
  lng: 139.745
DISPLAY_MARKER_THRESHOLD = 11

checkedList = []

main = (stations) ->
  initMap = (lat = MAP_CENTER_DEFAULT.lat, lng = MAP_CENTER_DEFAULT.lng, zoom = 13) ->
    polygons = []
    markers = []
    raderMarkers = []
    stationsFilter = null
    currentLatLng = null
    currentZoom = null
    enablePolygon = true
    enableMarker = true

    iconList = 
      sphereRed: new google.maps.MarkerImage 'images/icon-sphere_red.png', new google.maps.Size(8, 8), new google.maps.Point(0, 0), new google.maps.Point(4, 4)
      sphereGray: new google.maps.MarkerImage 'images/icon-sphere_gray.png', new google.maps.Size(8, 8), new google.maps.Point(0, 0), new google.maps.Point(4, 4)
      raderCenter: new google.maps.MarkerImage 'http://www.google.com/mapfiles/gadget/arrowSmall80.png', new google.maps.Size(31, 27), new google.maps.Point(0, 0), new google.maps.Point(9, 27)

    map = new (google.maps.Map)(document.getElementById('map'),
      zoom: zoom
      center: new (google.maps.LatLng)(lat, lng)
      mapTypeId: google.maps.MapTypeId.ROADMAP
      streetViewControl: false
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

      if !enableMarker or currentZoom < DISPLAY_MARKER_THRESHOLD
        markers.forEach (v) ->
          v.setMap null

    redraw = (force = false) ->
      newLatLng = map.getCenter()
      newZoom = map.getZoom()
      if !force and currentLatLng and Math.abs(currentLatLng.lat() - newLatLng.lat()) < 0.2 and Math.abs(currentLatLng.lng() - newLatLng.lng()) < 0.2 and currentZoom and currentZoom == newZoom
        return

      currentLatLng = newLatLng
      currentZoom = newZoom

      map.clearOverlays()

      bufferRange = 0.5
      bounds = map.getBounds()
      stationsFilter = stations.filter((v) ->
        v.lat > bounds.getSouthWest().lat() - bufferRange and v.lat < bounds.getNorthEast().lat() + bufferRange and v.lng > bounds.getSouthWest().lng() - bufferRange and v.lng < bounds.getNorthEast().lng() + bufferRange
      )

      if enablePolygon
        voronoi = d3.geom.voronoi().clipExtent([[0, 110], [60, 170]])
        # voronoi = d3.geom.voronoi()
        voronois = voronoi(stationsFilter.map (v) -> [v.lat, v.lng])

      stationsFilter.forEach (d, i) ->
        if enablePolygon
          paths = voronois[i].map (v) ->
            if Object.keys v != 'point'
              new (google.maps.LatLng)(v[0], v[1])

          if checkedList.indexOf(d.cd) != -1
            fillColor = '#f00'
          else
            fillColor = 'transparent'
          if currentZoom >= DISPLAY_MARKER_THRESHOLD
            strokeWeight = 2
          else
            strokeWeight = 1

          polygon = new google.maps.Polygon
            paths: paths
            strokeColor: '#f00'
            strokeOpacity: .4
            strokeWeight: strokeWeight
            fillColor: fillColor
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

        if enableMarker and currentZoom >= DISPLAY_MARKER_THRESHOLD
          if !markers[d.cd]
            if +d.type == 2
              icon = iconList.sphereGray
            else
              icon = iconList.sphereRed

            marker = new google.maps.Marker
              position: new (google.maps.LatLng)(d.lat, d.lng)
              map: map
              icon: icon
              title: d.name
            markers[d.cd] = marker
          else if markers[d.cd].getMap() == null
            markers[d.cd].setMap map

    addRaderMarker = (latLng, dist, i) ->
      raderMarkers.push new google.maps.Marker
        position: latLng
        map: map
        icon: 'http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=' + (i + 1) + '|ff6633|000000'
        animation: google.maps.Animation.DROP
        clickable: false

    raderCenter = new google.maps.Marker
      icon: iconList.raderCenter
      animation: google.maps.Animation.DROP
      draggable: true

    google.maps.event.addListener raderCenter, 'dragend', (e) ->
      distances = []
      stationsFilter.forEach (d, i) ->
        latLng = new (google.maps.LatLng)(d.lat, d.lng)
        distances.push
          dist: google.maps.geometry.spherical.computeDistanceBetween latLng, e.latLng
          cd: d.cd
          latLng: latLng

      distances.sort (a, b) ->
        d3.ascending a.dist, b.dist

      raderMarkers.forEach (v) ->
        v.setMap null
      raderMarkers = []

      for d, i in distances[0..11]
        setTimeout (d, i) ->
          addRaderMarker d.latLng, d.dist, i
        , i * 150, d, i

    google.maps.event.addListener map, 'idle', ->
      redraw()

    $(".js-btn-polygon").on 'click', ->
      if $(this).hasClass('disabled')
        $(this).removeClass('disabled')
        $(this).addClass('red')
        enablePolygon = true
      else
        $(this).removeClass('red')
        $(this).addClass('disabled')
        enablePolygon = false
      redraw true
      $(".fixed-action-btn").removeClass('active')

    $(".js-btn-marker").on 'click', ->
      if $(this).hasClass('disabled')
        $(this).removeClass('disabled')
        $(this).addClass('red')
        enableMarker = true
      else
        $(this).removeClass('red')
        $(this).addClass('disabled')
        enableMarker = false
      redraw true
      $(".fixed-action-btn").removeClass('active')

    $(".js-btn-rader").on 'click', ->
      if $(this).hasClass('disabled')
        $(this).removeClass('disabled')
        $(this).addClass('red')
        raderCenter.setPosition map.getCenter()
        raderCenter.setMap map
      else
        $(this).removeClass('red')
        $(this).addClass('disabled')
        raderMarkers.forEach (v) ->
          v.setMap null
        raderCenter.setMap null
      $(".fixed-action-btn").removeClass('active')

  if location.hash and matches = location.hash.match /#([+-]?[\d\.]+),([+-]?[\d\.]+)/
    initMap matches[1], matches[2]
  else if navigator.geolocation
    navigator.geolocation.getCurrentPosition (position) ->
      if position?.coords
        initMap position.coords.latitude, position.coords.longitude
      else
        initMap()
    , ->
      initMap()
  else
    initMap()

$ ->
  if localStorage.getItem('ekimemo_checkedList')
    try
      checkedList = JSON.parse(localStorage.getItem('ekimemo_checkedList'))
    catch e
      console.log e
      checkedList = []

  d3.csv './data/stations.csv', (stations) ->
    main stations
