BS.AgentBrowse = {
  chooseSelected: function(dropDown, baseUrl) {
    dropDown = $j(dropDown);
    var value = dropDown.val();
    if (value) {
      document.location.href = baseUrl + "&buildId=" + value;
    }
  }
};
