<%@include file="/include-internal.jsp"%>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="cameFromUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>

<style type="text/css">
  .vsettingsProjectErrors {
    margin-left: 1em;
  }
  .vsettingsErrorFile {
  }
</style>
<c:set var="projectsCount" value="${fn:length(errors)}"/>
<c:set var="errorsBlockId" value="vsettingsErrors_${showMode}_${root.externalId}"/>
<span>
  Failed to apply versioned settings changes from VCS Root <admin:vcsRootName vcsRoot="${root.parent}" editingScope="none" cameFromUrl="${cameFromUrl}"/>
  because of configuration errors in
  <strong>${projectsCount}</strong> project<bs:s val="${projectsCount}"/>. <c:if test="${showMode == inplaceMode}"><a href="javascript:;" onclick="$j('#${errorsBlockId}').toggle();">Show details &raquo;</a></c:if>
</span>
<div class="vsettingsErrors" id="${errorsBlockId}" style="display: ${showMode == inplaceMode ? 'none' : ''}">
  <c:forEach var="projectErrors" items="${errors}">
    <div>
      <c:set var="projectErrorsCount" value="${fn:length(projectErrors.errors)}"/>
      <c:set var="projectErrorsBlockId" value="vsettingsProjectErrors_${showMode}_${projectErrors.project.externalId}"/>
      <div>
        <admin:projectName project="${projectErrors.project}" addToUrl="&tab=versionedSettings&subTab=config"/>
      </div>
      <div id="${projectErrorsBlockId}" class="vsettingsProjectErrors">
        <c:forEach var="error" items="${projectErrors.errors}">
          <div>
            <c:if test="${not empty error.key}">
              <%-- don't show empty file for for validation errors --%>
              <span class="vsettingsErrorFile"><c:out value="${error.key}"/>:</span>
            </c:if>
            <span><c:out value="${error.value}"/></span>
          </div>
        </c:forEach>
      </div>
    </div>
  </c:forEach>
</div>

