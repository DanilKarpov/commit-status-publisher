<%@ page import="jetbrains.buildServer.serverSide.oauth.azuredevops.AzureDevOpsOAuthProvider" %>
<%@include file="/include-internal.jsp"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="showMode" type="java.lang.String" scope="request"/>
<jsp:useBean id="availableParents" type="java.util.List" scope="request"/>
<c:set var="connectionName" value="<%=AzureDevOpsOAuthProvider.DISPLAY_NAME%>"/>
<bs:linkCSS>
  /css/admin/adminMain.css
</bs:linkCSS>
<style type="text/css">
  table.runnerFormTable {
    width: 80%;
  }

  table.runnerFormTable th {
    width: 20em;
  }
</style>
<div>
  <table class="runnerFormTable">
    <tr>
      <th><label for="name">Parent project:<l:star/></label></th>
      <td>
        <bs:projectsFilter name="parentId" id="parentId"
                           projectBeans="${availableParents}"
                           selectedProjectExternalId="${project.externalId}"
                           disableRoot="${showMode == 'createBuildTypeMenu'}"/>
        <span class="error" id="errorParent"></span>
      </td>
    </tr>
    <tr>
      <th>
        Choose a repository:<l:star/>
      </th>
      <td>
        <div id="repositoriesPage">
          <forms:saving id="loadRepositories" style="float: none;"/> Please wait...
        </div>
        <script type="text/javascript">
          $j('#loadRepositories').show();
          BS.ajaxUpdater($('repositoriesPage'), '${pageUrl}&content=embed', {
            method: 'get',
            evalScripts: true
          });
        </script>
      </td>
    </tr>
  </table>
</div>