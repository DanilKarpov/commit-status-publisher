<%@include file="/include-internal.jsp"%>
<jsp:useBean id="currentProject" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<style type="text/css">
  .readOnlyNote {
    display: none;
  }
</style>

<div class="editProjectIsolationSettings">
  <jsp:include page="/admin/projectIsolation.html"/>
</div>