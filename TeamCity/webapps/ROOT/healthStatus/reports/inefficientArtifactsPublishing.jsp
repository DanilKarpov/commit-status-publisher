<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>

<c:set var="build" value="${healthStatusItem.additionalData['build']}"/>
<div>
  Build <bs:buildLinkFull build="${build}"/> published a lot of small artifacts. It is faster and more efficient to pack the files in a zip and publish the zip file instead.<bs:help file="Configuring General Settings" anchor="artifactPaths"/>
</div>
