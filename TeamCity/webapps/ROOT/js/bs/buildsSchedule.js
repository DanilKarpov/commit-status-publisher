(function($) {
  BS.BuildsSchedule = {
    initDatePicker: function () {
      var opts = {
        dateFormat: "dd M yy",
        showButtonPanel: true,
        onSelect: function () {
          BS.BuildsScheduleForm.submitForm();
        }
      };
      $("#scheduleDate").datepicker(opts);

    },

    adjustUpcoming: function (anotherDay) {
      if (anotherDay) {
        BS.Util.hide("isSameDateFilter");
        $("#showOnlyUpcoming").prop('checked', false);
      } else {
        BS.Util.show("isSameDateFilter");
      }
    }
  };

  BS.BuildsScheduleForm = OO.extend(BS.AbstractWebForm, {
    submitForm: function () {
      var self = this;
      BS.Util.show("buildScheduleOptions_progress");
      BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {

        makeError: function (name, elem) {
          $j('#error_' + name).text(elem.firstChild.nodeValue);
        },

        onBeginSave: function (form) {
          BS.ErrorsAwareListener.onBeginSave(form);
        },

        onScheduleDateError: function (elem) {
          this.makeError("scheduleDate", elem);
        },

        onCompleteSave: function (form, responseXML, err) {
          BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
          self.onComplete(form, responseXML, err);
        }

      }));
      return false;
    },

    formElement: function () {
      return $('#buildScheduleOptions').get(0);
    },

    onComplete: function (form, responseXML, err) {
      if (!err) {
        form.setSaving(true);
        $('#buildsScheduleContainer').get(0).refresh('buildScheduleOptions_progress', null, function () {
          form.enable();
        });
      } else {
        BS.Util.hide("buildScheduleOptions_progress");
        form.enable();
      }
    },

    toggleAdvanced: function(toggle) {
      $('#advanced-fields').removeClass('hidden');
      $(toggle).addClass('hidden');
      return false;
    }
  });
})(jQuery);
