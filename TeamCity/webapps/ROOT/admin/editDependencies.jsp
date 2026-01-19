<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<admin:editBuildTypePage selectedStep="dependencies">
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/admin/editDependencies.css
    </bs:linkCSS>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <%@include file="snapshotDependencies.jsp"%>
    <br/>
    <%@include file="artifactDependenciesTable.jsp"%>
  </jsp:attribute>
</admin:editBuildTypePage>

