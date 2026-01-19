<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="agent" value="${healthStatusItem.additionalData['agent']}"/>
<c:set var="lastBuildDate" value="${healthStatusItem.additionalData['lastBuildDate']}"/>
<div style="vertical-align: middle">
  <bs:agent agent="${agent}"/> is not used<c:if test="${lastBuildDate != null}"> since <strong><bs:date value="${lastBuildDate}"/></strong></c:if>
</div>
