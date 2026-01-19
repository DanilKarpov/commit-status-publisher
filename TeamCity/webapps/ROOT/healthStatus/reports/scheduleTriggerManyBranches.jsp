<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="buildType" value="${healthStatusItem.additionalData['buildType']}"/>
<c:set var="triggerId" value="${healthStatusItem.additionalData['triggerId']}"/>
<c:set var="link"><admin:editBuildTypeTriggerLink buildType="${buildType}" triggerId="${triggerId}" withoutLink="true"/></c:set>

<a href='${link}'>Schedule trigger settings</a> in <admin:viewOrEditBuildTypeLinkFull buildType="${buildType}"/>
  can trigger builds in <strong><bs:out value="${healthStatusItem.additionalData['branchesCount']}"/></strong> branches at once
