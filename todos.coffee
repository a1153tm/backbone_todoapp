$ ->
  class Todo extends Backbone.Model
    defaults:
      done: false
  
    initialize: =>
      @.on 'remove', ->
        @unset 'order'
  
    toggle: ->
      @save {done: !@get('done')}
  
  class TodoList extends Backbone.Collection
    model: Todo
  
    localStorage: new Backbone.LocalStorage("todos")
  
    comparator: "order"
  
    add: (models) =>
      models = [models] unless _.isArray models
      _.each models, (model) =>
        if model instanceof Todo and !model.has('order')
          model.set 'order', @nextOrder()
          super.add model
        else if !model.hasOwnProperty('order')
          model.order = @nextOrder()
          super.add model

    done: ->
      @where {done: true}
  
    remaining: ->
      @where {done: false}

    nextOrder: ->
      return 1 unless @.length
      @.last().get('order') + 1

    swap: (idA, idB) ->
      modelA = @get idA
      modelB = @get idB
      if modelA and modelB
        tmp = modelA.get 'order'
        modelA.save 'order', modelB.get('order'), {silent: true}
        modelB.save 'order', tmp, {silent: true}
        @sort()

  _template = _.memoize ((selector) ->
      _.template($(selector).html())
    )
  
  class TodoView extends Backbone.View
    tagName: 'li'
  
    events:
      'click .toggle':    'toggleDone'
      'dblclick .view':   'edit'
      'click a.destroy':  'clear'
      'keypress .edit':   'updateOnEnter'
      'blur .edit':       'close'
  
      'dragstart':        'onDragStart'
      'dragend':          'onDragEnd'
      'drop':             'onDrop'
      'dragover':         'onDragOver'
  
    initialize: ->
      _.bindAll @
      @moving = false
      @listenTo @model, 'change', @render
      @listenTo @model, 'destroy', @remove
  
    template: (data) ->
      _temp = _template("#item-template")
      _temp(data)
      
    render: ->
      @$el.html @template(@model.toJSON())
      @$el.toggleClass 'done', @model.get('done')
      @input = @.$ '.edit'
      return this
  
    toggleDone: ->
      @model.toggle()
  
    edit: ->
      return if @editing
      @editing = true
      @$el.addClass 'editing'
      @input.focus()
  
    clear: ->
      @model.destroy()
  
    updateOnEnter: (e) ->
      return false unless @editing
      @close() if e.keyCode == 13
  
    close: ->
      return unless @editing
      @editing = false
      value = @input.val()
      unless value
        @clear()
      else
        @model.save {title: value}
        @$el.removeClass 'editing'
      
    onDragStart: (e) ->
      @moving = true
      @$el.addClass 'moving'
      e.originalEvent.dataTransfer.setData('application/x-todo-id', @model.id)

    onDragEnd: (e) ->
      @moving = false
      @$el.removeClass 'moving'

    onDrop: (e) ->
      e.preventDefault()
      unless @moving
        id = e.originalEvent.dataTransfer.getData('application/x-todo-id')
        @model.collection.swap(id, @model.id)

    onDragOver: (e) ->
      e.preventDefault()

  class AppView extends Backbone.View
    el: '#todoapp'
  
    template: (data) ->
      _temp = _template("#stats-template")
      _temp(data)
  
    events:
      "keypress #new-todo": "createOnEnter"
      "click #clear-completed": "clearCompleted"
      "click #toggle-all": "toggleAllComplete"
  
    initialize: ->
      _.bindAll @

      @collection = new TodoList
      @input = @.$ "#new-todo"
      @allCheckbox = @.$("#toggle-all")[0]

      @listenTo @collection, 'add', @addOne
      @listenTo @collection, 'all', @render
      @listenTo @collection, 'sort', @reorder
  
      @list = @.$("#todo-list")
      @footer = @.$ 'footer'
      @main = @.$ "#main"
  
      @collection.fetch()
  
    render: ->
      done = @collection.done().length
      remaining = @collection.remaining().length

      if @collection.length
        @main.show()
        _html = @template { done: done, remaining: remaining }
        @footer.show().html(_html)
      else
        @main.hide()
        @footer.hide()
      @allCheckbox.checked = !remaining
      @

    addOne: (todo) ->
      view = new TodoView({model: todo})
      @list.append(view.render().el)

    reorder: ->
      @list.html ''
      @addAll()
      
    addAll: ->
      @collection.each @addOne

    createOnEnter: (e) ->
      return unless e.keyCode == 13
      value = @input.val()
      @collection.create (title: value)
      @input.val ''
  
    clearCompleted: ->
      _.invoke @collection.done(), 'destroy'
      false

    toggleAllComplete: ->
      done = @allCheckbox.checked
      @collection.each (todo) ->
        todo.save { done: done }

  new AppView
