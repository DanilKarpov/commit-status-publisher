<%@include file="/include-internal.jsp"%>
<jsp:useBean id="currentProject" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<style type="text/css">
  .readOnlyNote {
    display: none;
  }
</style>

<div class="editProjectPage">
<jsp:include page="/admin/projectVcsRoots.html?projectId=${currentProject.externalId}" >
  <jsp:param name="cameFromUrl" value="${pageUrl}"/>
</jsp:include>
</div>