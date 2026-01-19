<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="cameFromUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>

<c:set var="buildType" value="${healthStatusItem.additionalData['buildType']}"/>
<c:set var="triggerName" value="${healthStatusItem.additionalData['triggerName']}"/>

<div>
  Multiple identical enabled <c:out value="${triggerName}"/>s in <admin:editBuildTypeLinkFull buildType="${buildType}" cameFromUrl="${cameFromUrl}"/>.
</div>
  <c:if test="${not buildType.readOnly}">
    <div>
    <admin:editBuildTypeTriggerLink buildType="${buildType}" triggerId="">
      Edit
    </admin:editBuildTypeTriggerLink>
    </div>
  </c:if>
