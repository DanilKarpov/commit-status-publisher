<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="queue" tagdir="/WEB-INF/tags/queue" %>
<jsp:useBean id="buildQueue" type="jetbrains.buildServer.controllers.queue.BuildQueueBean" scope="request"/>
<queue:queueEstimates buildQueue="${buildQueue}"/>
