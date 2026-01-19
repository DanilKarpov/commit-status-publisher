
BS.HistoryTable = OO.extend(BS.AbstractWebForm, {
  setSaving: function(saving) {
    var savingElem = $("savingFilter");
    if (savingElem) {
      if (saving) {
        BS.Util.show(savingElem);
      } else {
        BS.Util.hide(savingElem);
      }
    }
  },

  formElement: function() {
    return $('historyFilter');
  },

  update: function(moreParams) {
    $j(function() {
      if ($j('#all-tags-switch').length) {
        if (moreParams) {
          moreParams += '&' + 'allTags=' + $j('#all-tags-switch').prop('checked');
        } else {
          moreParams = 'allTags=' + $j('#all-tags-switch').prop('checked');
        }
      }

      $('historyTable').refresh('savingFilter', moreParams, function() {
        Form.enable(BS.HistoryTable.formElement());
      });
    })
  },

  doSearch: function() {
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SimpleListener, {
      onBeginSave: function(form) {
        Form.disable(form.formElement());
        form.setSaving(true);
      },
      onCompleteSave: function() {
        BS.HistoryTable.update();
      }
    }));
    return false;
  },

  setTagAndSearch: function(value, name) {
    $j('form input[name=' + name + ']').val(value || '');
    BS.HistoryTable.doSearch();
    return false;
  },

  resetTagAndSearch: function() {
    $j('form input[name=tag]').val('');
    $j('form input[name=privateTag]').val('');
    BS.HistoryTable.doSearch();
    return false;
  }
});
