<%@ page contentType="text/html;charset=UTF-8" language="java" session="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="afn" uri="/WEB-INF/functions/authz" %>
<jsp:useBean id="buildData" type="jetbrains.buildServer.serverSide.SBuild" scope="request"/>
<c:set var="buildType" value="${buildData.buildType}"/><c:if test="${not empty error}">
  <c:out value="${error}"/>: <b><c:out value="${startPage}"/></b>.
  <c:if test="${not empty isProjectTab}">
    Artifacts taken from build <bs:buildTypeLink buildType="${buildType}"/> ::
    <bs:resultsLink build="${buildData}" noPopup="true">#<c:out value="${buildData.buildNumber}"/></bs:resultsLink>
  </c:if>
</c:if
><c:if test="${empty error}">
  <c:if test="${not empty isProjectTab}">
    <p>
      Data was taken from <c:out value="${buildType.fullName}"/>,
      <bs:resultsLink build="${buildData}">build <c:out value="${buildData.buildNumber}"/></bs:resultsLink>
      started at <bs:date value="${buildData.startDate}"/>
    </p>
  </c:if>
  <c:choose>
    <c:when test="${empty isDisabled}">
      <c:url value='/repository/download/${buildType.externalId}/${buildData.buildId}:id/${startPage}?redirectSupported=false' var="iframeUrl"/>
      <bs:iframe url="${iframeUrl}"/>
    </c:when>
    <c:otherwise>
      <div class="attentionComment">
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>Tabs with custom reports are disabled for security reasons. The domain isolation protection for artifacts is enabled but the artifacts' URL is not configured.<br>
        <c:choose>
          <c:when test="${afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}">
            To keep the server protected and enable the reports, configure the artifacts' URL in <a href="<c:url value="/admin/admin.html?item=serverConfigGeneral"/>">Global Settings</a>. Alternatively, you can disable the domain isolation (not recommended).
          </c:when>
          <c:otherwise>
            Ask your administrator to consider configuring the artifacts URL in Global Settings.
          </c:otherwise>
        </c:choose>
        <bs:help file="Artifacts+Domain+Isolation"/>
      </div>
    </c:otherwise>
  </c:choose>
</c:if>
