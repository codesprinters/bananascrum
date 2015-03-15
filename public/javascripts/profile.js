bs.profile = {};

bs.profile.editableTheme = function() {
  var themeNames = [];
  var i;
  for (i = 0; i < bs._available_themes.length; i += 1) {
    var name = bs._available_themes[i].name;
    themeNames[i] = name;
  }
  $(this).cseditable({
    type:         'select',
    submitBy:     'change',
    cancelLink:   'Cancel',
    editClass:    'inplaceeditor-form nosort editor-field',
    startEditing: true,
    onSubmit:     bs.profile.themeOnSubmit,
    onReset:      bs.backlog.enableHighlight,
    onEdit:       bs.backlog.suppressHighlight,
    options:      themeNames
  });
};

bs.profile.themeOnSubmit = function(values) {
  var selectedOption = parseInt(values['current']);
  var newThemeId = bs._available_themes[selectedOption].id;
  var newThemeName = bs._available_themes[selectedOption].name;
  var nameElement = $(this);

  var successHandler = function(env) {
    $(document).html(env.html);
    return location.reload();
  };

  bs.put(profilePath(), {"user[theme_id]": newThemeId}, successHandler, null, 'json');
};
