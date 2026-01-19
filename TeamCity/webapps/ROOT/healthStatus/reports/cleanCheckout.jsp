<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>

<c:set var="differentSettingsBuildTypes" value="${healthStatusItem.additionalData['differentSettingsBuildTypes']}"/>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="cameFromUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>

<div>
  The following build configurations have the same checkout directory but different VCS settings, this may lead to unnecessary clean checkout on agent:<bs:help file="Build Checkout Directory" anchor="Customcheckoutdirectory"/>
</div>
<div>
  <ul>
    <c:forEach items="${differentSettingsBuildTypes}" var="bt">
      <c:choose>
        <c:when test="${afn:permissionGrantedForBuildType(bt, 'EDIT_PROJECT')}">
          <li><admin:viewOrEditBuildTypeLinkFull buildType="${bt}" step="vcsRoots" cameFromUrl="${cameFromUrl}"/></li>
        </c:when>
        <c:when test="${afn:permissionGrantedForBuildType(bt, 'VIEW_PROJECT')}">
          <li><bs:buildTypeLinkFull buildType="${bt}"/></li>
        </c:when>
        <c:otherwise>
          <li><em>Inaccessible build configuration</em></li>
        </c:otherwise>
      </c:choose>
    </c:forEach>
  </ul>
</div>
