<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<admin:editBuildTypePage selectedStep="general" isAccessError="true">
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/admin/accessError.css
    </bs:linkCSS>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <c:choose>
      <c:when test="${buildForm.template}">
        <c:set var="homeHref"><bs:projectUrl projectId="${buildForm.project.externalId}" /></c:set>
        <admin:accessError type="template" homeHref="${homeHref}" />
      </c:when>
      <c:otherwise>
        <c:set var="homeHref"><c:url value="/viewType.html?buildTypeId=${buildForm.settingsBuildType.externalId}"/></c:set>
        <admin:accessError type="build configuration" homeHref="${homeHref}"/>
      </c:otherwise>
    </c:choose>
  </jsp:attribute>
</admin:editBuildTypePage>
