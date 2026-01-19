<%@ include file="/include-internal.jsp"
%><%@taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth"
%><jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"
/><jsp:useBean id="parents" type="java.util.List" scope="request"
/><c:url value='/admin/moveProject.html' var="moveAction"

/><bs:modalDialog formId="moveProjectForm"
                      title="Move Project"
                      action="${moveAction}"
                      closeCommand="BS.MoveProjectForm.cancelDialog()"
                      saveCommand="BS.MoveProjectForm.submitMove()">
  <label for="parentId" >Move to project:<bs:help file="Creating+and+Editing+Projects" anchor="MovingProject"/></label>

  <input type="hidden" name="parentId" id="newParentId" />
  <div id="moveToNewParentIdSelect" style="display: inline-block; margin-left: 16px;"></div>
  <script>
    {
      const includedProjects = [
        <c:forEach var="bean" items="${parents}">
          '<c:out value="${bean.project.externalId}"/>',
        </c:forEach>
      ];
      ReactUI.renderConnected(document.getElementById('moveToNewParentIdSelect'), ReactUI.ProjectBuildTypeSelect, {
        buildTypesSelectable: false,
        projectsSelectable: true,
        expandAll: true,
        includedProjects,
        disabledProjects: [
          '<c:out value="${project.parentProject.externalId}"/>',
          '<c:out value="${project.externalId}"/>'
        ],
        includeRoot: includedProjects.includes('_Root'),
        onSelect(item) {
          var id = item.id;
          document.getElementById('newParentId').value = id;
          var moveImpossibleEl = $('moveProjectImpossibleDescription');

          $('moveProjectButton').disable();
          BS.MoveForm.checkCanMove(id, 'projectId=' + '${project.externalId}', 'Project', function(msg, canProceed) {
            if (msg != null) {
              moveImpossibleEl.show();
              moveImpossibleEl.innerHTML = msg;
              if (canProceed) {
                $('moveProjectButton').enable();
              }
            } else {
              moveImpossibleEl.hide();
              moveImpossibleEl.innerHTML = '';
              $('moveProjectButton').enable();
            }
          });
        }
      });
    }
  </script>
  <span class="error" id="errorParent"></span>

  <c:set var="subProjectsNum" value="${fn:length(project.projects)}"/>
  <c:if test="${subProjectsNum > 0}">
    <div style="margin-top: 0.5em;">
      This project has <b>${subProjectsNum}</b> subproject<bs:s val="${subProjectsNum}"/>, which will also be moved.
    </div>
  </c:if>

  <div id="moveProjectImpossibleDescription" style="display: none; margin-top: 0.5em;"></div>

  <oauth:tokenProjectScopeWarning project="${project}" parentProjectIdElement="newParentId" forCopy="false" />

  <div class="popupSaveButtonsBlock">
    <forms:submit label="Move" id="moveProjectButton" disabled="true"/>
    <forms:cancel onclick="BS.MoveProjectForm.cancelDialog()"/>
    <forms:saving id="moveProjectProgress"/>
  </div>

  <input type="hidden" name="projectId" value="${project.externalId}"/>
</bs:modalDialog>
