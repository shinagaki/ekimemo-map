checkedList = []

main = (stations) ->
  if navigator.geolocation
    navigator.geolocation.getCurrentPosition (position) ->
      initMap position.coords.latitude, position.coords.longitude
  else
    initMap 35.659, 139.745

  fixInfoWindow = ->
    set = google.maps.InfoWindow::set
    google.maps.InfoWindow::set = (key, val) ->
      if key == 'map'
        if !@get('noSupress')
          return
      set.apply this, arguments

  initMap = (lat, lon) ->
    map = new (google.maps.Map)(document.getElementById('map'),
      zoom: 13
      center: new (google.maps.LatLng)(lat, lon)
      mapTypeId: google.maps.MapTypeId.ROADMAP
      disableDoubleClickZoom: true)
    fixInfoWindow()
    overlay = new (google.maps.OverlayView)

    overlay.onAdd = ->
      svg = d3.select(@getPanes().floatPane).append('div').attr('class', 'svg-overlay').append('svg')
      svgOverlay = svg.append('g')
      markerOverlay = this
      overlayProjection = markerOverlay.getProjection()

      googleMapProjection = (lat, lng) ->
        googleCoordinates = new (google.maps.LatLng)(lat, lng)
        pixelCoordinates = overlayProjection.fromLatLngToDivPixel(googleCoordinates)
        [
          pixelCoordinates.x + 10000
          pixelCoordinates.y + 10000
        ]

      google.maps.event.addListener map, 'idle', ->
        overlay.draw()

      overlay.draw = ->
        bufferRange = 0.5
        bounds = map.getBounds()
        pointdata = stations.filter((v) ->
          v.lat > bounds.getSouthWest().lat() - bufferRange and v.lat < bounds.getNorthEast().lat() + bufferRange and v.lon > bounds.getSouthWest().lng() - bufferRange and v.lon < bounds.getNorthEast().lng() + bufferRange
        )
        positions = []
        pointdata.forEach (d) ->
          positions.push googleMapProjection(d.lat, d.lon)

        polygons = d3.geom.voronoi(positions)

        pathAttr = 
          'class': (d) ->
            if checkedList.indexOf(d.cd) != -1
              'cell checked'
            else
              'cell'
          'stroke': 'rgba(255, 0, 0, .4)'
          'stroke-width': 2
          'fill': 'none'
          'pointer-events': 'all'
          'd': (d, i) ->
            'M' + polygons[i].join('L') + 'Z'
        svgOverlay.selectAll('path.cell, circle, text').data(pointdata).exit().remove()
        svgOverlay.selectAll('path.cell').data(pointdata).attr(pathAttr).enter().append('svg:path').attr(pathAttr).on 'dblclick', (d) ->
          if checkedList.indexOf(d.cd) != -1
            checkedList = checkedList.filter((v) ->
              v != d.cd
            )
            d3.select(this).classed 'checked', false
          else
            checkedList.push d.cd
            d3.select(this).classed 'checked', true
          localStorage.setItem 'ekimemo_checkedList', JSON.stringify(checkedList)

        circleAttr = 
          'r': '.5em'
          'stroke': '#666'
          'stroke-width': 1
          'fill': (d, i) ->
            if +d.type == 1
              return 'red'
            else if +d.type == 2
              return 'gray'
          'fill-opacity': 0.6
          'cursor': 'pointer'
          'cx': (d, i) ->
            positions[i][0]
          'cy': (d, i) ->
            positions[i][1]
        svgOverlay.selectAll('circle').data(pointdata).attr(circleAttr).enter().append('svg:circle').attr circleAttr
        textAttr = 
          'text-anchor': 'middle'
          'x': (d, i) ->
            positions[i][0]
          'y': (d, i) ->
            positions[i][1]
          'dy': '1.4em'
          'fill': 'blue'
          'font-size': '1.2em'
          'font-weight': 'bold'
          'font-family': 'Hiragino Kaku Gothic ProN, \'ヒラギノ角ゴ Pro W3\', Meiryo, \'メイリオ\''
          'pointer-events': 'none'
        svgOverlay.selectAll('text').data(pointdata).attr(textAttr).text((d, i) ->
          d.name
        ).enter().append('svg:text').attr(textAttr).text (d, i) ->
          d.name

    overlay.setMap map

if localStorage.getItem('ekimemo_checkedList')
  try
    checkedList = JSON.parse(localStorage.getItem('ekimemo_checkedList'))
  catch e
    console.log e
    checkedList = []
d3.csv './data/stations.csv', (stations) ->
  main stations
