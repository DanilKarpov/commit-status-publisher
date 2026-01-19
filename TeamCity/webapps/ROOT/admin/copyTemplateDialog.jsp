<%@ include file="/include-internal.jsp"
%><jsp:useBean id="sourceTemplate" type="jetbrains.buildServer.serverSide.BuildTypeTemplate" scope="request"
/><jsp:useBean id="editableProjectBeans" type="java.util.List" scope="request"
/><c:url value='/admin/copyTemplate.html' var="copyAction"/>

<bs:modalDialog formId="copyTemplateForm"
                title="Copy Template"
                action="${copyAction}"
                closeCommand="BS.CopyTemplateForm.cancelDialog()"
                saveCommand="BS.CopyTemplateForm.submitCopy()">
  <label for="copyTemplateProjectId" class="tableLabel">Copy to project:<l:star/></label>
  <input type="hidden" id="copyTemplateProjectId" name="projectId" value="<c:out value="${sourceTemplate.project.externalId}"/>" />
  <div id="copyTemplateProjectIdSelect"></div>
  <script>
    {
      const includedProjects = [
        <c:forEach var="bean" items="${editableProjectBeans}">
          '<c:out value="${bean.project.externalId}"/>',
        </c:forEach>
      ];
      ReactUI.renderConnected(document.getElementById('copyTemplateProjectIdSelect'), ReactUI.ProjectBuildTypeSelect, {
        buildTypesSelectable: false,
        projectsSelectable: true,
        expandAll: true,
        includedProjects,
        selected: {
          nodeType: 'project',
          id: '<c:out value="${sourceTemplate.project.externalId}"/>',
        },
        includeRoot: includedProjects.includes('_Root'),
        onSelect(item) {
          const input = document.getElementById('copyTemplateProjectId');
          input.value = item.id;
          input.dispatchEvent(new Event('change'));
        }
      });
    }
  </script>
  <span class="error" id="error_projectId"></span>

  <p>
    <label for="newTemplateName" class="tableLabel">New name:<l:star/></label>
    <forms:textField id="newTemplateName" name="newName" className="longField" value="${sourceTemplate.name}"/>
    <span class="error" id="error_newName" style="margin-left: 8em"></span>
  </p>

  <p>
    <label for="newExternalId" class="tableLabel">New ID:<l:star/><bs:help file="BuildconfigurationID"/></label>
    <forms:textField id="newTemplateExternalId" name="newExternalId" className="longField" maxlength="256" value=""/>
    <span class="error" id="error_newTemplateExternalId" style="margin-left: 8em"></span>
  </p>

  <div class="popupSaveButtonsBlock">
    <forms:submit name="copyTemplate" id="copyTemplateButton" label="Copy"/>
    <forms:cancel onclick="BS.CopyTemplateForm.cancelDialog()" showdiscardchangesmessage="false"/>
    <forms:saving id="copyTemplateProgress"/>
  </div>

  <input type="hidden" name="templateId" id="templateId" value="${sourceTemplate.externalId}"/>
  <input type="hidden" name="sourceProjectId" id="sourceProjectId" value="${sourceTemplate.project.externalId}"/>

  <script type="text/javascript">
    BS.AdminActions.prepareTemplateIdGenerator("newTemplateExternalId", "newTemplateName", $("copyTemplateProjectId"));
  </script>
</bs:modalDialog>
