<%@ include file="/include-internal.jsp" %>
<%--@elvariable id="selectArchiveStep" type="jetbrains.buildServer.controllers.admin.projectsImport.SelectArchiveStepBean"--%>
<c:set value="${fn:length(selectArchiveStep.availableArchives) > 0}" var="archivesExist"/>
<jsp:useBean id="importDisabled" type="java.lang.Boolean" scope="request" />
<jsp:useBean id="importDisabledReason" type="java.lang.String" scope="request" />

<h2>Select Backup File</h2>

<p>
  <c:choose>
    <c:when test="${serverIsEmpty && !isCloudInstance}">
      <forms:attentionComment>
        Projects Import is not recommended for this server: the import is used to add projects to an existing server with other projects.
        <div>
            The current server does not contain any active projects, consider using server move.
        </div>
        <div>
          If you proceed with projects import, you will have to perform some operations manually: review the <bs:helpLink file="Projects+Import" anchor="Dataexcludedfromimport">import limitations.</bs:helpLink>
        </div>
        <div style="margin-top: 0.5em;">
          <bs:helpLink file="Projects+Import" anchor="ProjectsImportorServerMove">Read more...</bs:helpLink>
        </div>
      </forms:attentionComment>

    </c:when>
    <c:otherwise>
      <div>
        Projects Import is used to add projects to an existing server with other projects.
        If you need to move all the server data to a different machine, use server move.
        <bs:helpLink file="Projects+Import" anchor="ProjectsImportorServerMove"><bs:helpIcon/></bs:helpLink>
      </div>
    </c:otherwise>
  </c:choose>
</p>

<form id="selectArchiveForm" data-import-disabled="${importDisabled}" onsubmit="return BS.ProjectsImport.SelectArchiveForm.submit()" method="post">
  <table class="runnerFormTable">
    <c:choose>
      <c:when test="${archivesExist}">
        <tr>
          <th><label>Import from:</label></th>
          <td>
            <forms:select id="archiveSelector" name="selectedArchive" enableFilter="true" onchange="BS.ProjectsImport.SelectArchiveForm.archiveSelectorChange();">
              <forms:option value="">-- Please select a backup file --</forms:option>
              <c:forEach var="archive" items="${selectArchiveStep.availableArchives}">
                <forms:option value="${archive.path}" selected="${fn:length(selectArchiveStep.availableArchives) == 1}"><c:out value="${archive.name}"/></forms:option>
              </c:forEach>
            </forms:select>
            <div class="smallNote" style="margin-left: 0;">Directory for files to import: <strong><c:out value="${selectArchiveStep.archivesDirectory}"/></strong></div>
            <span class="error" id="archiveVersionMismatchError"></span>
            <span class="error" id="invalidArchiveError"></span>
            <span class="error" id="projectImportUnexpectedError"></span>

            <div id="uploadArchiveButton">
              <forms:addButton onclick="BS.ProjectsImport.UploadArchiveDialog.show(); return false;">Upload Archive</forms:addButton>
            </div>
          </td>
        </tr>
      </c:when>
      <c:otherwise>
        <tr>
          <td colspan="2">
            There are no backup files in <strong><c:out value="${selectArchiveStep.archivesDirectory}"/></strong>. Upload the file or put it in the directory and refresh this page.
            <div id="uploadArchiveButton">
              <forms:addButton onclick="BS.ProjectsImport.UploadArchiveDialog.show(); return false;">Upload Archive</forms:addButton>
            </div>
          </td>
        </tr>
      </c:otherwise>
    </c:choose>
  </table>

  <c:if test="${fn:length(selectArchiveStep.availableArchives) > 0}">
    <div class="saveButtonsBlock">
      <forms:submit id="submitArchiveButton" label="Configure Import Scope" disabled="${importDisabled}"/>
      <forms:saving id="selectArchiveProgress" savingTitle="Archive is analyzing..."/>
      <c:if test="${importDisabled}">
        <br>
        Cannot start projects import process right now: ${importDisabledReason}
      </c:if>
    </div>
  </c:if>
</form>

<c:url var="action" value="/admin/projectsImportUpload.html"/>
<bs:dialog dialogId="uploadImportedArchiveDialog" title="Upload archive" closeCommand="BS.ProjectsImport.UploadArchiveDialog.close()">
  <forms:multipartForm id="uploadImportedArchiveForm" action="${action}" targetIframe="hidden-iframe" onsubmit="return BS.ProjectsImport.UploadArchiveDialog.validate();">
    <input type="text" id="fileName" name="fileName" value="" class="mediumField" style="display:none;"/>
    <table class="runnerFormTable">
      <tr>
        <th>Imported Archive</th>
        <td>
          <forms:file name="fileToUpload" size="28"/>
          <div id="uploadError" class="error hidden"></div>
        </td>
      </tr>
    </table>
    <div class="popupSaveButtonsBlock">
      <forms:submit id="uploadImportedArchiveDialogSubmit" label="Upload"/>
      <forms:cancel onclick="BS.ProjectsImport.UploadArchiveDialog.close()"/>
      <forms:saving id="uploadingProgress" savingTitle="Uploading..."/>
    </div>
  </forms:multipartForm>
</bs:dialog>


<script type="text/javascript">
  BS.ProjectsImport.SelectArchiveForm.init();
  BS.ProjectsImport.UploadArchiveDialog.prepareFileUpload();
</script>
