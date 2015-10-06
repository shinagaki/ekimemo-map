gulp = require 'gulp'
jade = require 'gulp-jade'
stylus = require 'gulp-stylus'
autoprefixer = require 'autoprefixer-stylus'
coffee = require 'gulp-coffee'
browserSync = require 'browser-sync'
plumber = require 'gulp-plumber'
ghPages = require 'gulp-gh-pages'
del = require 'del'

paths =
  src:
    jade: './source/jade'
    stylus: './source/stylus'
    coffee: './source/coffee'
    json: './source/json'
  dest:
    html: './build'
    css: './build/css'
    js: './build/js'
    json: './build/json'

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

gulp.task 'copy', ->
  gulp.src "#{paths.src.json}/**/*"
    .pipe gulp.dest "#{paths.dest.json}"

gulp.task 'clean', (callback) ->
  del ["#{paths.dest.html}/**/*"], callback

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

gulp.task 'default', ['clean', 'jade', 'stylus', 'coffee', 'copy', 'watch', 'server']
