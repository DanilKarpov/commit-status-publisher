<%@include file="/include-internal.jsp" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="showMode" type="java.lang.String" scope="request"/>
<jsp:useBean id="availableParents" type="java.util.List" scope="request"/>
<bs:linkCSS dynamic="true">
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
      <th><label for="name">Parent TeamCity project:<l:star/></label></th>
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
        Choose a Space project:<l:star/>
      </th>
      <td>
        <div id="projectsPage">
          <forms:saving id="loadProjects" style="float: none;"/> Please wait...
        </div>
        <script type="text/javascript">
          $j('#loadProjects').show();
          BS.ajaxUpdater($('projectsPage'), '${pageUrl}&content=embed', {
            method: 'get',
            evalScripts: true
          });
        </script>
      </td>
    </tr>
    <tr class="repositoriesRow" style="display: none;">
      <th>
        Choose a repository:<l:star/>
      </th>
      <td>
        <div id="loadRepositoriesMessage">
          <forms:saving id="loadRepositories" style="float: none;"/> Please wait...
        </div>
        <div id="repositoriesPage"></div>
      </td>
    </tr>
  </table>
</div>
