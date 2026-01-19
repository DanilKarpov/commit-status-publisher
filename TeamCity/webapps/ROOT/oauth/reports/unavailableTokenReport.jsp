<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.reports.UnavailableTokenReport" %>
<%@include file="/include-internal.jsp"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="vcsRootReportType" value="<%=UnavailableTokenReport.InvalidTokenReportType.VCS.value%>"/>
<c:set var="buildFeatureReportType" value="<%=UnavailableTokenReport.InvalidTokenReportType.BUILD_FEATURE.value%>"/>
<c:set var="vcsRootKey" value="<%=UnavailableTokenReport.VCS_ROOT_DATA_KEY%>"/>
<c:set var="buildTypeKey" value="<%=UnavailableTokenReport.BUILD_TYPE_DATA_KEY%>"/>
<c:set var="missingTokenKey" value="<%=UnavailableTokenReport.MISSING_TOKEN_DATA_KEY%>"/>
<c:set var="wrongScopeTokenKey" value="<%=UnavailableTokenReport.WRONG_SCOPE_TOKEN_DATA_KEY%>"/>
<c:set var="wrongProjectKey" value="<%=UnavailableTokenReport.WRONG_PROJECT_DATA_KEY%>"/>
<c:set var="reportTypeKey" value="<%=UnavailableTokenReport.REPORT_TYPE_KEY%>"/>
<c:set var="featureIdKey" value="<%=UnavailableTokenReport.FEATURE_ID_KEY%>"/>
<c:set var="featureDisplayNameKey" value="<%=UnavailableTokenReport.FEATURE_DISPLAY_NAME_KEY%>"/>
<c:set var="cameFromUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>
<c:set var="missingTokenId" value="${healthStatusItem.additionalData[missingTokenKey]}"/>
<c:set var="wrongScopeToken" value="${healthStatusItem.additionalData[wrongScopeTokenKey]}"/>
<c:set var="wrongProject" value="${healthStatusItem.additionalData[wrongProjectKey]}"/>
<c:set var="reportType" value="${healthStatusItem.additionalData[reportTypeKey]}"/>


<c:if test="${reportType.equals(vcsRootReportType)}">
  <c:set var="vcsRoot" value="${healthStatusItem.additionalData[vcsRootKey]}"/>
  <div>
    Unable to utilize the auth token specified in the VCS root settings of
    <admin:editVcsRootLink vcsRoot="${vcsRoot}" editingScope="" cameFromUrl="${cameFromUrl}"><c:out value="${vcsRoot.name}"/></admin:editVcsRootLink>
    in the project <admin:editProjectLink projectId="${vcsRoot.project.externalId}"><c:out value="${vcsRoot.project.fullName}"/></admin:editProjectLink>.
    <c:choose>
      <c:when test="${not empty missingTokenId}">
        TeamCity failed to locate the token or this token has expired.
      </c:when>
      <c:when test="${not empty wrongScopeToken}">
        The token was issued for a different project and can not be used for project <c:out value="${wrongProject.fullName}"/>.
      </c:when>
    </c:choose>
    Open the VCS root settings and ensure auth settings are correct and/or acquire a new token
  </div>
</c:if>

<c:if test="${reportType.equals(buildFeatureReportType)}">
  <c:set var="featureId" value="${healthStatusItem.additionalData[featureIdKey]}"/>
  <c:set var="buildType" value="${healthStatusItem.additionalData[buildTypeKey]}"/>
  <c:set var="featureDisplayName" value="${healthStatusItem.additionalData[featureDisplayNameKey]}"/>
  <c:url var="featureUrl" value="/admin/editBuildFeatures.html?init=1&id=buildType:${buildType.externalId}#editFeature=${featureId}"/>

  <div>
    Unable to utilize the auth token specified in the
    <a href="${featureUrl}">
        ${featureDisplayName} build feature
    </a>
    settings
    in the build configuration <admin:editBuildTypeLinkFull step="buildFeatures" buildType="${buildType}"/>.
    <c:choose>
      <c:when test="${not empty missingTokenId}">
        TeamCity failed to locate the token or this token has expired.
      </c:when>
      <c:when test="${not empty wrongScopeToken}">
        The token was issued for a different project and can not be used for project <c:out value="${wrongProject.fullName}"/>.
      </c:when>
    </c:choose>
    Open the feature settings and ensure auth settings are correct and/or acquire a new token
  </div></c:if>