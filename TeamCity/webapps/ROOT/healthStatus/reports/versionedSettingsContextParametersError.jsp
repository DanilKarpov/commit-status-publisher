<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@include file="/include-internal.jsp" %>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>

<c:choose>
  <c:when test="${showMode eq inplaceMode}">
    <span>
      Failed to generate project settings from the DSL code: required context parameters not specified<br/>
      <admin:editProjectLink projectId="${project.externalId}" addToUrl="&tab=versionedSettings&subTab=config#status">See details</admin:editProjectLink>
    </span>
  </c:when>
  <c:otherwise>
    Failed to generate settings for <admin:projectName project="${project}" addToUrl="&tab=versionedSettings&subTab=config#status"/>
    from the DSL code: required context parameters not specified<br/>
  </c:otherwise>
</c:choose>
