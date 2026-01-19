BS.AgentsList = {
  groupByPools: function (key) {
    BS.Util.show("groupByPoolsProgress");
    BS.User.setBooleanProperty(key, !$('groupByPoolsCheckbox').checked, {
      afterComplete: function () {
        $('agentsList').refresh();
      }
    });
  }
};
