<%@ page import="jetbrains.buildServer.controllers.admin.healthStatus.HealthStatusReportBean" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="configErrorsConverter" type="jetbrains.buildServer.web.util.ConfigErrorsCleanupConverter" scope="request"/>

<c:set var="configErrors" value="${healthStatusItem.additionalData['configErrors']}"/>
<c:set var="allProblems" value="<%=HealthStatusReportBean.ALL_PROBLEMS%>"/>
<c:set var="archivedProjectsProblems" value="<%=HealthStatusReportBean.ARCHIVED_PROJECTS_PROBLEMS%>"/>
<%--@elvariable id="configErrors" type="jetbrains.buildServer.serverSide.ConfigurationErrors"--%>

<c:if test="${configErrors != null}">
  There are <bs:helpLink file="Common+Problems#%22Critical+error+in+configuration+file%22+errors">critical configuration errors</bs:helpLink>
  that prevent cleaning up the data of deleted projects and build configurations.

  <%--@elvariable id="errors" type="jetbrains.buildServer.web.util.ConfigErrorsCleanupConverter.UserAvailableConfigErrors"--%>
  <c:set var="errors" value="${configErrorsConverter.getUserAvailableErrors(configErrors)}"/>
  <c:set var="configErrorsLink" value="admin.html?item=healthStatus#minSeverity=ERROR&scopeProjectId=${allProblems}&selectedCategoryId=critical_config_errors"/>
  <c:set var="archivedProjectsConfigErrorsLink" value="admin.html?item=healthStatus#minSeverity=ERROR&scopeProjectId=${archivedProjectsProblems}&selectedCategoryId=critical_config_errors"/>

  <c:if test="${errors.visibleProjectErrorsCount == 1}">
    <div>1 project configuration error. See the <a href="<c:url value='${configErrorsLink}'/>">related report.</a></div>
  </c:if>
  <c:if test="${errors.visibleProjectErrorsCount > 1}">
    <div>${errors.visibleProjectErrorsCount} project configuration errors. See the <a href="<c:url value='${configErrorsLink}'/>">related report.</a></div>
  </c:if>

  <c:if test="${errors.invisibleProjectErrorsCount == 1}">
    <div>1 project configuration error cannot be viewed due to the lack of permissions. Contact your system administrator to fix it.</div>
  </c:if>
  <c:if test="${errors.invisibleProjectErrorsCount > 1}">
    <div>${errors.invisibleProjectErrorsCount} project configuration errors cannot be viewed due to the lack of permissions. Contact your system administrator to fix them.</div>
  </c:if>

  <c:if test="${errors.visibleGlobalErrorsCount == 1}">
    <div>1 server configuration error. See the <a href="<c:url value='${configErrorsLink}'/>">related report.</a></div>
  </c:if>
  <c:if test="${errors.visibleGlobalErrorsCount > 1}">
    <div>${errors.visibleGlobalErrorsCount} server configuration errors. See the <a href="<c:url value='${configErrorsLink}'/>">related report.</a></div>
  </c:if>

  <c:if test="${errors.invisibleGlobalErrorsCount == 1}">
    <div>1 server configuration error cannot be viewed due to the lack of permissions. Contact your system administrator to fix it.</div>
  </c:if>
  <c:if test="${errors.invisibleGlobalErrorsCount > 1}">
    <div>${errors.invisibleGlobalErrorsCount} server configuration errors cannot be viewed due to the lack of permissions. Contact your system administrator to fix them.</div>
  </c:if>

  <c:if test="${errors.archiveProjectsCount == 1}">
    <div>1 server configuration error is related to an <bs:helpLink file="Archiving+Projects">archived project</bs:helpLink>. See the <a href="<c:url value='${archivedProjectsConfigErrorsLink}'/>">related report.</a></div>
  </c:if>
  <c:if test="${errors.archiveProjectsCount > 1}">
    <div>${errors.archiveProjectsCount} server configuration errors are related to <bs:helpLink file="Archiving+Projects">archived projects</bs:helpLink>. See the <a href="<c:url value='${archivedProjectsConfigErrorsLink}'/>">related report.</a></div>
  </c:if>
</c:if>