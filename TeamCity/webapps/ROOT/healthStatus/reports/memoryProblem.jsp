<%@ include file="/include-internal.jsp"
%><%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin"
%><%@ taglib prefix="tags" tagdir="/WEB-INF/tags/tags"
%><jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"
/><c:set var="data" value="${healthStatusItem.additionalData}"
/>
<c:choose>
  <c:when test="${data.gcOverheadWarning}">
    TeamCity server is suffering from low memory problems. More than <strong>${util:formatPercent(data.gcOverhead, 1)}</strong> of time was spent in memory cleaning.
    ${util:formatFileSize(data.heap.used, 1)} used of ${util:formatFileSize(data.heap.max, 1)} total heap available. See the TeamCity
    <bs:helpLink file="SettingUpMemorySettingsForTeamCityServer">documentation</bs:helpLink> for possible solutions.
  </c:when>
  <c:when test="${data.singlePoolUsage}">
    TeamCity server memory usage for <strong><c:out value="${data.poolName}"/></strong> pool reached <strong>${util:formatPercent(data.averageMemoryUsagePercent, 100)}</strong> of
    <strong>${util:formatFileSize(data.maxSize, 1)}</strong> maximum available. Total heap used: ${util:formatFileSize(data.heap.used, 1)} of ${util:formatFileSize(data.heap.max, 1)}.
    See the TeamCity <bs:helpLink file="SettingUpMemorySettingsForTeamCityServer">documentation</bs:helpLink> for possible solutions.
  </c:when>
  <c:when test="${data.permGenUsage}">
    TeamCity server memory usage for <strong>PermGen</strong> pool reached <strong>${util:formatPercent(data.averageMemoryUsagePercent, 100)}</strong> of
    <strong>${util:formatFileSize(data.maxSize, 1)}</strong> maximum available. It's recommended to increase maximum PermGen pool size as described in
    <bs:helpLink file="SettingUpMemorySettingsForTeamCityServer">documentation</bs:helpLink>.
  </c:when>
  <c:when test="${data.totalMemoryUsage}">
    Average TeamCity server memory usage during the last <strong>${data.statisticCalculationTimeMinutes}</strong> minutes exceeded
    <strong>${util:formatPercent(data.averageMemoryUsagePercent, 100)}</strong> of <strong>${util:formatFileSize(data.maxSize, 1)}</strong> total heap available.
    This can cause significant server slowdown.
    See the TeamCity <bs:helpLink file="SettingUpMemorySettingsForTeamCityServer">documentation</bs:helpLink> for possible solutions.
  </c:when>
</c:choose>