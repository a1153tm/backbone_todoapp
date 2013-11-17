define([
  'underscore',
  'backbone',
  './Page',
  'jst/mobile'
],
function (_, Backbone, Page, JST) {

  'use strict';

  return Page.extend({
    events: {
      pagehide: 'remove'
    },
    options: {
      transition: 'slideup'
    },
    initialize: function () {
      this.listenTo(this.model, 'invalid', this.renderValidationMessage);
      this.listenTo(this.model, 'sync', function (model) {
        model.collection.add(model);
        Backbone.history.navigate(model.id, true);
      });
    },
    // View methods
    // ------------
    render: function () {
      this.$el.html(JST['mobile/new']({source: this.presenter()}));
      // Since `submit` is undelegate-able in Internet Explorer, it is needed
      // to add event listener directrly to the form tag.
      this.$('form').on('submit', _.bind(this.onSubmit, this));
      return this;
    },
    renderValidationMessage: function (model, errors) {
      _.each(errors, function (value, name) {
        this.$("#error_" + name)
          .addClass("active")
          .text(value);
      }, this);
      return this;
    },
    // Controller methods
    // ------------------
    onSubmit: function (e) {
      e.preventDefault();
      var model = this.model;
      this.$('.error.active').removeClass('active');
      model.save(this.getValues());
    },
    // Helper methods
    // --------------
    presenter: function () {
      return this.model.toEscapedJSON();
    },
    getValues: function () {
      var values = {};
      _.each(this.$('form').serializeArray(), function (obj) {
        values[obj.name] = obj.value;
      });
      return values;
    }
  });
});
