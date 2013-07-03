"use strict"

module = angular.module 'bootstrapExampleApp', ['ui.bootstrap']

module.config ($routeProvider, $locationProvider) ->
  $locationProvider.hashPrefix('!')
  $routeProvider.when("/photos/:q/:page",
    templateUrl: "views/gallery.html"
    controller: "GalleryCtrl"
    resolve: 
      photos: ($q, $http, $route) ->
        # call to flickr prior to calling the view's controller
        deferred = $q.defer()
        flickrAPIKey = "7b2a664477422ccf0e00880283becc36"
        flickrUrl = "http://api.flickr.com/services/rest"
        photos = null
        params = 
          method: "flickr.photos.search"
          format: "json"
          text: $route.current.params.q || 'gorilla'
          api_key: flickrAPIKey
          jsoncallback: 'JSON_CALLBACK'
          per_page: 42
          page: +$route.current.params.page || 1

        $http.jsonp(flickrUrl, params: params).success  (data) -> deferred.resolve data.photos

        deferred.promise
  ).otherwise redirectTo: "/photos/#{localStorage.getItem('q') || 'gorilla'}/1"
  
module.controller 'GalleryCtrl', ($scope, $location, $route, photos) ->
  getQuery = -> query = $scope.q || $route.current.params.q
  goToPage = (pageNo) ->
    $scope.photos = null # to show the loader
    $scope.empty = false
    $location.path "/photos/#{encodeURIComponent getQuery()}/#{pageNo}"
  # make pictures and query available to the view
  $scope.photos = photos
  $scope.query = getQuery()
  # search submission
  $scope.search = -> goToPage 1
  # utilities (should probably be in separate service)
  $scope.getThumbUrl = (photo) -> "http://farm#{photo.farm}.staticflickr.com/#{photo.server}/#{photo.id}_#{photo.secret}_s.jpg"
  $scope.getUrl = (photo) -> "http://farm#{photo.farm}.staticflickr.com/#{photo.server}/#{photo.id}_#{photo.secret}.jpg"
  # pagination
  $scope.noOfPages = photos.pages
  $scope.currentPage = +$route.current.params.page
  $scope.setPage = goToPage
  $scope.noResults = photos.total
  $scope.empty = true if photos.photo.length is 0

  # modal
  $scope.open = (photo) ->
    $scope.photo = photo
    $scope.details = true
  $scope.close = -> $scope.details = false

# directive to resize and center the pictures
# so that the list looks good whatever the ratio of the picture is
module.directive "swResize", ->
  (scope, element, attr) ->
    img = element[0]
    img.onload = ->
      thumbEl = document.getElementsByClassName("thumbnail")[0]
      placeholderRatio = thumbEl.offsetWidth / thumbEl.offsetHeight
      imgRatio = img.width / img.height
      if imgRatio > placeholderRatio
        # landscape ratio
        # resize
        img.style.height = "#{thumbEl.offsetHeight}px"
        # center
        marginLeft = -(thumbEl.offsetHeight * imgRatio - thumbEl.offsetWidth) / 2
        img.style.marginLeft = "#{marginLeft}px"
      else
        # portrait ratio
        # resize
        img.style.width = "#{thumbEl.offsetWidth}px"
        # center
        marginTop = -(thumbEl.offsetWidth / imgRatio - thumbEl.offsetHeight) / 2
        img.style.marginTop = "#{marginTop}px"
