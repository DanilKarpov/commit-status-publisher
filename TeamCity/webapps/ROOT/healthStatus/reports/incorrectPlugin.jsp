<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<c:set var="globalMode" value="<%=HealthStatusItemDisplayMode.GLOBAL%>"/>

<c:set var="infos" value="${healthStatusItem.additionalData['infos']}"/>
<%--@elvariable id="errors" type="java.util.List<jetbrains.buildServer.plugins.PluginAdditionalMessage>"--%>
<c:set var="errors" value="${healthStatusItem.additionalData['errors']}"/>
<c:choose>
  <c:when test="${not empty errors}">
    <%--@elvariable id="infos" type="java.util.List<jetbrains.buildServer.plugins.bean.ServerPluginInfo>"--%>
    There <c:out value='${fn:length(errors) == 1 ? "is an error" : "are errors"}'/> in ${fn:length(infos)} loaded plugin<bs:s val="${fn:length(infos)}"/>.
    <authz:authorize anyPermission="CHANGE_SERVER_SETTINGS">
  <jsp:attribute name="ifAccessGranted">
    <a href="<c:url value="/admin/admin.html?item=plugins" />">View details on the Plugin List page.</a>
  </jsp:attribute>
  <jsp:attribute name="ifAccessDenied">
    Please contact your server administrator.
  </jsp:attribute>
    </authz:authorize>
    <c:if test="${globalMode == showMode}">
      <ul style="margin-top: 0; margin-bottom: 0">
        <c:forEach items="${infos}" var="info" end="4">
          <%--@elvariable id="info" type="jetbrains.buildServer.plugins.bean.ServerPluginInfo"--%>
          <li><c:out value="${info.pluginXml.info.displayName}"/></li>
        </c:forEach>
        <c:if test="${fn:length(infos) > 5}">
          <li>and <c:out value="${fn:length(infos) - 5}"/> more...</li>
        </c:if>
      </ul>
    </c:if>
  </c:when>

  <c:when test="${not empty infos}">
    <%--@elvariable id="infos" type="java.util.List<jetbrains.buildServer.plugins.bean.IncorrectPluginInfo>"--%>
    <strong>${fn:length(infos)}</strong> plugin<bs:s val="${fn:length(infos)}"/> <bs:are_is val="${fn:length(infos)}"/> not loaded due to error<bs:s
      val="${fn:length(infos)}"/> in the plugin descriptor.
    <authz:authorize anyPermission="CHANGE_SERVER_SETTINGS">
  <jsp:attribute name="ifAccessGranted">
    <a href="<c:url value="/admin/admin.html?item=plugins" />">View details on the Plugin List page.</a>
  </jsp:attribute>
  <jsp:attribute name="ifAccessDenied">
    Please contact your server administrator.
  </jsp:attribute>
    </authz:authorize>
    <c:if test="${globalMode == showMode}">
      <ul style="margin-top: 0; margin-bottom: 0">
        <c:forEach items="${infos}" var="info" end="4">
          <%--@elvariable id="info" type="jetbrains.buildServer.plugins.bean.IncorrectPluginInfo"--%>
          <li><c:out value="${info.pluginName}"/></li>
        </c:forEach>
        <c:if test="${fn:length(infos) > 5}">
          <li>and <c:out value="${fn:length(infos) - 5}"/> more...</li>
        </c:if>
      </ul>
    </c:if>
  </c:when>
  <c:otherwise>
  </c:otherwise>
</c:choose>

