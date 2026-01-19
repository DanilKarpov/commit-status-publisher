<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@include file="/include-internal.jsp" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>
<%--@elvariable id="errorDescription" type="java.lang.String"--%>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="cameFromUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>
<c:set var="project" value="${healthStatusItem.additionalData['project']}"/>
<c:set var="name" value="${healthStatusItem.additionalData['name']}"/>
<c:set var="id" value="${healthStatusItem.additionalData['id']}"/>
<c:set var="type" value="${healthStatusItem.additionalData['type']}"/>
<c:set var="errorDescription" value="${healthStatusItem.additionalData['errorDescription']}"/>
<c:set var="canEditProject" value="${afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}"/>

<c:set var="hash">editTracker=${type}&providerId=${id}</c:set>
<c:url var="url" value="/admin/editProject.html?init=1&projectId=${project.externalId}&tab=issueTrackers&#${hash}"/>

<c:choose>
  <c:when test="${canEditProject}">
    <c:set var="trackerDescription"><a href="${url}"><bs:out value="${name}"/></a></c:set>
  </c:when>
  <c:otherwise>
    <c:set var="trackerDescription"><bs:out value="${name}"/></c:set>
  </c:otherwise>
</c:choose>

<div>
  Issue tracker ${trackerDescription} refers to ${errorDescription}.
  Please check the connection and authentication settings or try to acquire a new token.
</div>
