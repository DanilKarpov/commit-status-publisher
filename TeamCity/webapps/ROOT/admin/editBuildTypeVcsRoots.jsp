<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<%@ taglib prefix="admfn" uri="/WEB-INF/functions/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<jsp:useBean id="pageUrl" type="java.lang.String" scope="request"/>
<c:set var="vcsRootsBean" value="${buildForm.vcsRootsBean}"/>
<admin:editBuildTypePage selectedStep="vcsRoots">
  <jsp:attribute name="head_include">
    <style type="text/css">
      #editCheckoutRulesForm .vcsTreeHandle {
        position: absolute;
      }
    </style>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <forms:modified/>
      <c:url value='/admin/editBuildTypeVcsRoots.html?id=${buildForm.settingsId}' var="formAction"/>
      <form id="editVcsSettingsForm" action="${formAction}" method="post" onsubmit="return BS.EditVcsRootsForm.applyVcsSettings()" class="clearfix">

      <admin:buildTypeVcsRootsForm buildTypeForm="${buildForm}"
                                   mode="${buildForm.template ? 'editTemplate' : 'editBuildType'}"
                                   pageUrl="${pageUrl}"
                                   branchesConfigured="${buildForm.branchesConfigured}"/>

      </form>
      <admin:editCheckoutRulesForm formAction="${formAction}" editableObjectId="settingsId=${buildForm.settingsId}" readOnly="${buildForm.readOnly}"/>
      <script type="text/javascript">
        BS.EditVcsRootsForm.setModified(${buildForm.stateModified});
        BS.EditVcsRootsForm.setupEventHandlers();
        BS.AvailableParams.attachPopups('settingsId=${buildForm.settingsId}', 'buildTypeParams');

        <c:if test="${buildForm.readOnly}">
        BS.EditVcsRootsForm.setReadOnly();
        </c:if>
      </script>
  </jsp:attribute>
</admin:editBuildTypePage>
