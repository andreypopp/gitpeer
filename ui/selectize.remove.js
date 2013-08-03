Selectize.registerPlugin('remove_button', function(options) {
  var self = this;

  this.settings.render.item = function(data) {
    var label = data[self.settings.labelField];
    return (
      '<div class="item"><a href="#" class="remove" tabindex="-1" title="Remove">'
      + '<i class="icon icon-remove"></i></a> ' +label + '</div>');
  };

  this.setup = (function() {
    var original = self.setup;
    return function() {
      original.apply(this, arguments);
      this.$control.on('click', '.remove', function(e) {
        e.preventDefault();
        e.stopPropagation();
        var $item = $(e.currentTarget).parent();
        var value = $item.attr('data-value');
        self.removeItem(value);
        if (self.items.length == 0) {
          self.showInput();
          self.$control_input.blur();
        }
      });
    };
  })();
});
