<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>
<jsp:useBean id="pageUrl" type="java.lang.String" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="globalMode" type="java.lang.Boolean" scope="request"/>

<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="returnUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>

<c:choose>
  <c:when test="${globalMode}">
    <c:set var="pluginInfos" value="${healthStatusItem.additionalData['pluginInfos']}"/>
    <c:set var="pluginInfosLength" value="${fn:length(pluginInfos)}"/>
    <jsp:useBean id="rootProject" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
    <c:if test="${pluginInfosLength > 0}">
      <c:choose>
        <c:when test="${pluginInfosLength == 1}">
          <c:set value="${pluginInfos[0]}" var="pluginInfo"/>
          <a href="<c:url value="${pluginInfo.pluginUrl}"/>">${pluginInfo.pluginDisplayName}</a> plugin is <b>no longer bundled</b>, but has usages, therefore <b>installation required</b>.
        </c:when>
        <c:otherwise>
          Following plugins are <b>no longer bundled</b>, but have usages, therefore <b>installation required</b>:
          <c:forEach items="${pluginInfos}" var="pluginInfo">
            <br/><a href="<c:url value="${pluginInfo.pluginUrl}"/>">${pluginInfo.pluginDisplayName}</a>
          </c:forEach>
        </c:otherwise>
      </c:choose>
      <c:if test="${not pageUrl.contains('item=healthStatus')}"><br/>See <admin:healthStatusReportLink minSeverity="ERROR" selectedCategory="unbundled.plugin.usage" project="${rootProject}">Server Health</admin:healthStatusReportLink> page for details
      </c:if>
    </c:if>
  </c:when>
  <c:otherwise>
    <c:set var="vcsRoot" value="${healthStatusItem.additionalData['vcsRoot']}"/>
    <c:set var="pluginInfo" value="${healthStatusItem.additionalData['pluginInfo']}"/>
    <admin:vcsRootName vcsRoot="${vcsRoot}" editingScope="" cameFromUrl="${returnUrl}"/> uses "${pluginInfo.usageDisplayName}" VCS type and requires <a href="<c:url value="${pluginInfo.pluginUrl}"/>">${pluginInfo.pluginDisplayName}</a> plugin installation
  </c:otherwise>
</c:choose>