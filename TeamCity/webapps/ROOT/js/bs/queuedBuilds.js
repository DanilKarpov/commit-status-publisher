BS.QueuedBuilds = {
  addTooltip: function(nodeId, started, elapsedTime, remainingTime) {
    var progressNode = $(nodeId);
    if (progressNode) {
      progressNode._title = "started: " + started + "<br>"
                      + elapsedTime + " passed<br>"
                      + remainingTime + " left<br>";
      if (!progressNode._eventsBound) {
        progressNode.on("mouseenter", function() {
          BS.Tooltip.showMessage($(nodeId), {shift:{x:10,y:20}}, $(nodeId)._title);
        });
        progressNode.on("mouseleave", function() {
          BS.Tooltip.hidePopup();
        });
        progressNode._eventsBound = true;
      }
    }
  }
};