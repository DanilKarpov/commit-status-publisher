<%@ include file="/include-internal.jsp"
%><jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"
/><jsp:useBean id="beans" type="java.util.List" scope="request"
/><bs:modalDialog formId="regenerateForm"
                  title="Bulk Edit IDs"
                  action="#"
                  closeCommand="BS.RegenerateForm.cancelDialog()"
                  saveCommand="BS.RegenerateForm.submit()"><c:choose
><c:when test="${empty beans}"
  ><div>Project does not have subprojects, build configurations, templates or VCS roots</div></c:when
><c:otherwise
  ><div>
    Current project ID is <b>${project.externalId}</b>.
    You can modify or reset the IDs for all inner projects, VCS roots, build configurations and templates.
  </div>

  <table class="copyProject regenerate">
    <tr class="subprojects">
      <td class="noBorder" colspan="2">
        <c:set var="length" value="${fn:length(beans)}"/>
        <c:set var="classes" value="${length > 5 ? 'gt-5' : ''} ${length > 10 ? 'gt-10' : ''} ${length > 15 ? 'gt-15' : ''}"/>
        <textarea id="mapping" class="${classes}" wrap="off"></textarea>
        <span class="error" id="error_mapping"></span>
      </td>
    </tr>
  </table>

  <div>
    <a class="regenerate" style="float: right;" href="#" title="Regenerate all IDs to comply default conventions"
       onclick="return BS.AdminActions.regenerateAll('${project.externalId}', 'mapping', 'currentExternalId');">Regenerate all</a>
    <div style="clear: both"></div>
  </div>

  <div class="attentionComment" style="margin-top: 1em">
    <bs:buildStatusIcon type="red-sign" className="warningIcon"/>Important: Modifying the ID will change all the URLs related to the project.
    It is highly recommended to update the ID in any of the URLs bookmarked or hard-coded in the scripts.
    The corresponding configuration and artifacts directory names on the disk will change too and it can take time.
  </div>

  <div class="popupSaveButtonsBlock">
    <forms:submit id="submitButton" label="Submit"/>
    <forms:cancel onclick="BS.RegenerateForm.cancelDialog()"/>
  </div>

  <input type="hidden" id="currentProjectName" value="<c:out value="${project.name}"/>"/>
  <input type="hidden" id="currentParentId" value="<c:out value="${project.parentProject.externalId}"/>"/>
  <input type="hidden" id="currentExternalId" name="projectId" value="${project.externalId}"/>

  <script type="text/javascript">
    BS.AdminActions.prepareSubstitutor("currentExternalId", "${project.externalId}", "mapping",
      [<c:forEach var="bean" items="${beans}">['${bean.key}', '${bean.externalId}', ${bean.indent}],</c:forEach>0]
    );
  </script></c:otherwise
></c:choose>
</bs:modalDialog>
