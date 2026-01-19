<%@ include file="/include-internal.jsp" %><%@
    taglib prefix="admin" tagdir="/WEB-INF/tags/admin"
%><jsp:useBean id="projectForm" type="jetbrains.buildServer.controllers.admin.projects.CreateProjectForm" scope="request"
/><c:set var="pageTitle" value="Create New Project" scope="request"/>
<%--@elvariable id="readOnly" type="java.lang.Boolean"--%>
<bs:linkCSS>
  /css/admin/projectForm.css
  /css/admin/adminMain.css
</bs:linkCSS>
<script type="text/javascript">
  <%@include file="/js/bs/editProject.js"%>
</script>
<div id="container" class="clearfix">
  <div class="editProjectPage" style="width: 70%;">
    <form action="<c:url value='/admin/createProject.html'/>" onsubmit="return BS.CreateProjectForm.submitCreateProject()" method="post" id="editProjectForm">
      <admin:projectForm projectForm="${projectForm}" disabled="${readOnly}"/>
      <div class="saveButtonsBlock">
        <forms:submit id="createProject" name="submitCreateProject" label="Create"/>
        <forms:saving/>
      </div>
    </form>
  </div>
</div>
<script type="text/javascript">
  document.forms[0].name.focus();
</script>
