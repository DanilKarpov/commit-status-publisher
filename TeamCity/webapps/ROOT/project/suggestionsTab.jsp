<%@ page import="jetbrains.buildServer.controllers.admin.healthStatus.HealthStatusTab" %>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@include file="/include-internal.jsp" %>
<jsp:useBean id="currentProject" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="items" type="java.util.Collection" scope="request"/>

<style type="text/css">
  .inplaceItemsList {
    margin-top: 1em;
  }
  .readOnlyNote {
    display: none;
  }
</style>

<c:if test="${empty buildForm and fn:length(currentProject.ownProjects) gt 0}">
<form action="<c:url value='/admin/editProject.html?projectId=FxCop&tab=projectSuggestions'/>" method="get">
<div class="actionBar">
  <forms:checkbox name="showSubProjectsSuggestions" checked="${param['showSubProjectsSuggestions'] eq 'true'}" onclick="this.form.submit()"/> <label for="showSubProjectsSuggestions">Show suggestions from subproject(s)</label>
  <input type="hidden" name="projectId" value="${currentProject.externalId}"/>
  <input type="hidden" name="tab" value="projectSuggestions"/>
</div>
</form>
</c:if>

<c:set var="containerId" value="projectSuggestions"/>
<bs:refreshable containerId="${containerId}" pageUrl="${pageUrl}">
  <div>Found <strong>${fn:length(items)}</strong> suggestion<bs:s val="${fn:length(items)}"/>.</div>

  <c:set var="applyVisibilityGlobally" value="${afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}"/>

  <div class="inplaceItemsList">
    <c:forEach items="${items}" var="res" varStatus="pos">
      <%--@elvariable id="res" type="jetbrains.buildServer.serverSide.healthStatus.impl.HealthStatusItemEx"--%>
      <div class="inplaceHealthStatusItem ${pos.last ? 'last' : ''}">
        <c:set var="extensionType" scope="request" value="${res.extension.type}"/>
        <c:set var="healthStatusItem" scope="request" value="${res}"/>
        <c:set var="showMode" scope="request" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
        <c:set var="healthStatusReportUrl" scope="request" value="<%=HealthStatusTab.URL%>"/>
        <c:set var="inlineMarkdownMessage" scope="request" value="${false}"/>
        <bs:itemSeverity severity="${res.category.severity}" suggestion="${res.category.id == 'suggestion'}"/>
        <bs:hideHealthItem item="${res}" refreshFunc="document.getElementById('${containerId}').refresh()"/>
        <jsp:include page="/showHealthStatusItem.html"/>
      </div>
    </c:forEach>
  </div>
</bs:refreshable>
<c:if test="${afn:permissionGrantedForProject(currentProject, 'VIEW_BUILD_CONFIGURATION_SETTINGS')}">
<p>
  <admin:healthStatusReportLink project="${currentProject}">View other health status items &raquo;</admin:healthStatusReportLink>
</p>
</c:if>
