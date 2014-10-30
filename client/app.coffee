define [
  'router'
  'jquery'
  'fastclick'
  'when'
  'models/track'
  'models/album'
  'models/artist'
  'models/release'
  'views/base/view'
  'views/base/tab'
  'views/base/bag'
  'views/search'
  'views/app_loader'
  'views/modal_manager'
  'views/album'
  'views/artists'
  'views/player2'
  'global'
  'oneline'
  'bus'
  'bacon'
  'views/search2'
  'moment/lang/de'
  'es5-shim'
], (
  router
  $
  fastclick
  w
  Track
  Album
  Artist
  Release
  MyView
  TabView
  BagView
  SearchView
  AppLoaderView
  ModalManager
  {AlbumCollectionView, ReleaseCollection}
  ArtistsView
  {Player}
  {instance: global}
  oneline
  Bus
  Bacon
  {searchView}
)->


  fastclick.attach(document.body)

  class ContentView extends TabView
    elementTemplate: '<ol class=content>'
  Object.defineProperty ContentView.prototype, 'elementTemplate',
    value: '<ol class=content>'

  class App
    constructor: ->
      @bus = @vent = new Bus

      @tracks = new Track.Repository
      @singletonTracks = @tracks.singletons()
      @albums = new Album.Repository
      @artists = new Artist.Collection(@albums, @singletonTracks)
      @recentAlbums = @albums.recent()
      @recentReleases = new Release.Recent(@tracks, @albums)


    start: ->
      appLoader = new AppLoaderView($('.app-loader'))
      @_start().done(
        => setTimeout (=> appLoader.finish()), 10
      , (e)=>
        appLoader.fail()
        throw e
      )

    _start: ->
      w.try =>
        oneline(document)

        @modal = new ModalManager($('body'))
        # TODO rename and abstract
        global.openNoAlbumDownload = @modal.openNoAlbumDownload.bind(@modal)
        global.openMessageDialog = @modal.openMessage.bind(@modal)
        MyView::app = global

        
        theSearchView = searchView()

        Bacon.combineTemplate(
          pattern:  theSearchView.search,
          download: theSearchView.downloadable
        ).assign global.search, 'dispatch'

        this.bus.on 'route:enter:search', (val)->
          theSearchView.$el.find('input').val(val)
          theSearchView.searchFragment.push(val)

        @artistSearchView = new BagView(
          theSearchView,
          new ArtistsView(@artists, @vent)
        )
        @albumsView = new ReleaseCollection(@recentReleases)

        @player = new Player(@tracks)

        @tabs = new ContentView
          artists: @artistSearchView
          albums:  @albumsView
        $('.container').append(@tabs.el, @player.el)

        @bus.on 'route:enter:index', => @tabs.select('artists').done()
        @bus.on 'route:enter:new',   => @tabs.select('albums').done()

        router(@vent)
      .then => w.all [
        @albums.fetchAll()
        @singletonTracks.fetchAll()
      ]

  return (window.a = new App)
