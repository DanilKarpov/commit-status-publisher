<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<l:li>
  <c:url var="exportUrl" value="/admin/editProject.html?projectId=${project.externalId}&tab=projectExport"/>
  <a href="${exportUrl}" title="Export project...">Export project...</a>
</l:li>
