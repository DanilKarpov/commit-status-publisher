<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="buildQueue" type="jetbrains.buildServer.controllers.queue.BuildQueueBean" scope="request"/>
<bs:refreshable containerId="buildQueueContainer" pageUrl="${pageUrl}">
<queue:buildQueueList hideSelection="true"/>
</bs:refreshable>
<script type="text/javascript">
  BS.QueuedBuildsPopup._currentBuildTypeId = "${buildQueue.filteredByBuildType.buildTypeId}";
  BS.QueuedBuildsPopup._currentProjectExternalId = "${buildQueue.filteredByBuildType.projectExternalId}";
</script>

