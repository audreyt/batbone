# obra++ for the Batbone name

@M = M = {}; @V = V = {}; @C = C = {}; @T = T = {}; @R = R = {}; @H = H = {}
@API = (url) -> "#{url}"
@ITEM = (fields="", opts={}) -> Backbone.Model.extend $.extend opts,
  defaults: do -> rv = {}; rv[i] = null for i in fields.split(' '); rv
@MODEL = (path="", opts={}) -> Backbone.Model.extend $.extend opts,
  url: API path
@LIST = (path="", model=null, opts={}) ->
  opts.model = model if model
  Backbone.Collection.extend $.extend opts,
    parse: ({data}) -> data
    comparator: (item) ->
      id = item.get('id')
      return 1/id if id?
      url = item.get('url')
      cid = Number(item.cid.substr(1))
      if url then cid else -cid
    url: API path
@VIEW = (tmpl="", model=null, opts={}) ->
  opts.model = new model if model
  Backbone.View.extend $.extend({
    el: $('#content')
    events: opts.events ? EVENTS().events
    template: tmpl
    initialize: ->
      @model?.bind e, @render, @ for e in ['reset', 'change', 'destroy']
      @model?.fetch()
    render: (opts={}) ->
      vars = opts.with ? {}
      vars = vars.toJSON?() if vars.toJSON?
      @$el.html @template($.extend({data: @model?.toJSON()}, vars)); @
    toJSON: ->
      rv = {}
      for { name, value } in @$('form').serializeArray()
        rv[name] = value if value? and value != ""
      return rv
  }, opts)
@TO = (view) -> -> (new view).render()
@ROUTE = (prefix="", table, opts={}) ->
  opts.routes ?= {}
  for k, v of table
    path = if k is "_" then "*default" else prefix + k
    method = path.replace(/\W+/g, '_')
    opts.routes[path] = method
    opts[method] = do (v) ->
      return TO v if v.prototype?.render?
      return v if typeof v is 'function'
      return -> @navigate v, trigger: yes, replace: yes
  new(Backbone.Router.extend opts)
@FORM = (cb) -> (e) ->
  e?.preventDefault?()
  cb?.call?(@, @toJSON())
@ELEM = (cb) -> (e) ->
  e?.preventDefault?()
  cb?.call?(@, $(e.target).data?())
@EVENTS = (events={}) -> events: $.extend({
  "submit form": FORM (data) ->
    if data.id
      @model.get(data.id).save data
    else
      @model.create(data)
  "reset form": -> @render()
}, events)

$ ->
  $('script[id][type^=text]').each -> T[@id] = @innerHTML
  for k, v of Handlebars.templates
    name = k.replace(/\.hbs$/, '')
    T[name] = v
    Handlebars.registerPartial name, v
  Handlebars.templates = T
  Handlebars.registerHelper k, v for k, v of H

  $('*[data-partial], *[data-yield]').each ->
    $_ = $(@)
    $_.html(T[$_.data('partial') or "_"+$_.data('yield')]?())

  setTimeout (->
    Backbone.history.start
      pushState: true
      root: "/b/"
    $('body').on 'click', 'a[href^=#][href!=#]', (e) ->
      e.preventDefault()
      Backbone.history.navigate $(@).attr('href').replace(
        /^#/, '/'
      ), trigger: yes, replace: yes
      return false
  ), 1
