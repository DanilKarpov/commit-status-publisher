<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<c:set var="selectedPreset" value="${healthStatusItem.additionalData['selectedPreset']}"/>

<div>TeamCity could not convert automatically to the log4j 2.x format the previously selected logging preset "${selectedPreset}".
  The default logging preset has been selected instead.
</div>