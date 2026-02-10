const gulp = require('gulp');
const less = require('gulp-less');
const concat = require('gulp-concat');
const cleanCSS = require('gulp-clean-css');
const sourcemaps = require('gulp-sourcemaps');
const uglify = require('gulp-uglify');

function styles() {
  return gulp.src(['less/*.less', 'antora-default-ui-hugo-theme/css/*.css'])
    .pipe(sourcemaps.init())
    .pipe(less())
    .pipe(concat('docs.css'))
    .pipe(cleanCSS())
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('static/styles'));
}

function scripts() {
  return gulp.src(['antora-default-ui-hugo-theme/js/*.js', 'js/*.js'])
    .pipe(sourcemaps.init())
    .pipe(concat('docs.js'))
    .pipe(uglify())
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('static/js'));
}

function watch() {
  gulp.watch(['less/*.less', 'antora-default-ui-hugo-theme/css/*.css'], styles);
  gulp.watch(['antora-default-ui-hugo-theme/js/*.js', 'js/*.js'], scripts);
}

const build = gulp.parallel(styles, scripts);

exports.styles = styles;
exports.scripts = scripts;
exports.build = build;
exports.watch = gulp.series(build, watch);
exports.default = build;