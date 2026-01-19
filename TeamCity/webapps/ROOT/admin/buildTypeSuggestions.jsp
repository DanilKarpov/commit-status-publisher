<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>

<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<admin:editBuildTypePage selectedStep="suggestions">
  <jsp:attribute name="head_include">
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <%@include file="/project/suggestionsTab.jsp"%>
  </jsp:attribute>
</admin:editBuildTypePage>