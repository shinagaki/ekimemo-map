MAP_CENTER_DEFAULT =
  lat: 35.659
  lng: 139.745
DISPLAY_MARKER_THRESHOLD = 11

checkedList = []
geocoder = null
map = null

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
      bgColor = (255 - i * 15).toString(16) + (220 - i * 8).toString(16) + '66'
      raderMarkers.push new google.maps.Marker
        position: latLng
        map: map
        icon: 'http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=' + (i + 1) + '|' + bgColor + '|000000'
        animation: google.maps.Animation.DROP
        clickable: false

    raderCenter = new google.maps.Marker
      icon: iconList.raderCenter
      animation: google.maps.Animation.DROP
      draggable: true

    useRader = (latLng) ->
      distances = []
      stationsFilter.forEach (d, i) ->
        stationLatLng = new (google.maps.LatLng)(d.lat, d.lng)
        distances.push
          dist: Math.sqrt(Math.pow(Math.abs(d.lat - latLng.lat()), 2) + Math.pow(Math.abs(d.lng - latLng.lng()), 2))
          cd: d.cd
          latLng: stationLatLng

      distances.sort (a, b) ->
        d3.ascending a.dist, b.dist

      raderMarkers.forEach (v) ->
        v.setMap null
      raderMarkers = []

      for d, i in distances[0..13]
        setTimeout (d, i) ->
          addRaderMarker d.latLng, d.dist, i
        , i * 150, d, i

    google.maps.event.addListener raderCenter, 'dragend', (e) ->
      useRader e.latLng

    google.maps.event.addListener map, 'idle', ->
      redraw()

    if !localStorage.getItem('ekimemo_updated') || $("#modal .update-date").data('updated') > localStorage.getItem('ekimemo_updated')
      localStorage.setItem 'ekimemo_updated', $("#modal .update-date").data('updated')
      $("#modal").openModal()

    $(".js-btn-polygon").on 'click', ->
      if $(this).hasClass('disabled')
        $(this).removeClass('disabled')
        $(this).addClass('teal')
        enablePolygon = true
      else
        $(this).removeClass('teal')
        $(this).addClass('disabled')
        enablePolygon = false
      $(".fixed-action-btn").removeClass('active')
      redraw true

    $(".js-btn-marker").on 'click', ->
      if $(this).hasClass('disabled')
        $(this).removeClass('disabled')
        $(this).addClass('cyan')
        enableMarker = true
      else
        $(this).removeClass('cyan')
        $(this).addClass('disabled')
        enableMarker = false
      $(".fixed-action-btn").removeClass('active')
      redraw true

    $(".js-btn-rader").on 'click', ->
      if $(this).hasClass('disabled')
        $(this).removeClass('disabled')
        $(this).addClass('light-blue')
        raderCenter.setPosition map.getCenter()
        useRader map.getCenter()
        raderCenter.setMap map
      else
        $(this).removeClass('light-blue')
        $(this).addClass('disabled')
        raderMarkers.forEach (v) ->
          v.setMap null
        raderCenter.setMap null
      $(".fixed-action-btn").removeClass('active')

    $(window).on 'hashchange', ->
      changedHash()

  changedHash = ->
    if matches = location.hash.match /#([+-]?[\d\.]+),([+-]?[\d\.]+)/
      initMap matches[1], matches[2]
    else
      if !geocoder
        geocoder = new google.maps.Geocoder()
      geocoder.geocode
        address: location.hash.substr(1)
      , (results, status) ->
        if status == google.maps.GeocoderStatus.OK
          if map
            map.setCenter results[0].geometry.location
          else
            initMap results[0].geometry.location.lat(), results[0].geometry.location.lng()
        else
          if !map
            initMap()

  if location.hash
    changedHash()
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
