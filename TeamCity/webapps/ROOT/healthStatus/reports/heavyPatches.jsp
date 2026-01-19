<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="buildTypeStat" type="jetbrains.buildServer.serverSide.healthStatus.reports.HeavyServerCheckoutPatchesReport.BuildTypeStat" scope="request"/>
<jsp:useBean id="threshold" type="java.lang.Long" scope="request"/>

Builds of <admin:viewOrEditBuildTypeLinkFull buildType="${buildTypeStat.buildType}"/> transferred <strong><bs:fileSize value="${buildTypeStat.totalPatchSize}"/></strong> of source code from the server to agents during the last 24 hours.
(<strong><bs:fileSize value="${buildTypeStat.maxPatchSize}"/></strong> during <bs:buildLink build="${buildTypeStat.heaviestBuild}">Build #<c:out value="${buildTypeStat.heaviestBuild.buildNumber}"/></bs:buildLink>)
<p>
  Switching to agent-side checkout can improve the server performance and reduce the total build time.<bs:help file="VCS+Checkout+Mode"/>
</p>


