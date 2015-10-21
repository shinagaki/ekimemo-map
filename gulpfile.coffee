gulp = require 'gulp'
jade = require 'gulp-jade'
stylus = require 'gulp-stylus'
autoprefixer = require 'autoprefixer-stylus'
coffee = require 'gulp-coffee'
browserSync = require 'browser-sync'
plumber = require 'gulp-plumber'
ghPages = require 'gulp-gh-pages'
del = require 'del'
concat = require 'gulp-concat'

paths =
  src:
    jade: './source/jade'
    stylus: './source/stylus'
    coffee: './source/coffee'
    images: './source/images'
    data: './source/data'
    vendors: './source/vendors'
  dest:
    html: './build'
    css: './build/css'
    js: './build/js'
    images: './build/images'
    data: './build/data'

gulp.task 'jade', ->
  gulp.src "#{paths.src.jade}/**/!(_)*.jade"
    .pipe plumber()
    .pipe jade
      pretty: true
    .pipe gulp.dest "#{paths.dest.html}"

gulp.task 'stylus', ->
  gulp.src "#{paths.src.stylus}/**/!(_)*.styl"
    .pipe plumber()
    .pipe stylus
      use:
        autoprefixer
          browsers: ['last 3 versions', 'ie 8']
    .pipe gulp.dest "#{paths.dest.css}"
    
gulp.task 'coffee', ->
  gulp.src "#{paths.src.coffee}/**/*.coffee"
    .pipe plumber()
    .pipe coffee
      bare: true
    .pipe gulp.dest "#{paths.dest.js}"

gulp.task 'concat', ['concat-js']

gulp.task 'concat-js', ->
  gulp.src [
    "#{paths.src.vendors}/**/*.js"
  ]
  .pipe concat 'vendors.js'
  .pipe gulp.dest "#{paths.dest.js}"

gulp.task 'copy', ->
  gulp.src "#{paths.src.data}/**/*"
    .pipe gulp.dest "#{paths.dest.data}"
  gulp.src "#{paths.src.images}/**/*"
    .pipe gulp.dest "#{paths.dest.images}"

gulp.task 'clean', (callback) ->
  del [
    "#{paths.dest.html}/**/*"
  ], callback

gulp.task 'watch', ->
  gulp.watch "#{paths.src.jade}/**/*.jade", ['jade']
  gulp.watch "#{paths.src.stylus}/**/*.styl", ['stylus']
  gulp.watch "#{paths.src.coffee}/**/*.coffee", ['coffee']

gulp.task 'browserSync', ->
  browserSync
    server:
      baseDir: paths.dest.html
    reloadDelay: 2000

gulp.task 'server', ['browserSync'], ->
  gulp.watch 'source/**', ->
    browserSync.reload() 

gulp.task 'deploy', ->
  gulp.src "#{paths.src.html}/**/*"
    .pipe ghPages()

gulp.task 'default', ['concat', 'jade', 'stylus', 'coffee', 'copy', 'watch', 'server']
