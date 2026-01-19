<%@ include file="/include-internal.jsp" %>
<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>

<bs:linkScript>
  /js/bs/collapseExpand.js
  /js/bs/runningBuilds.js
  /js/bs/blocks.js
  /js/bs/blockWithHandle.js
  /js/bs/blocksWithHeader.js
</bs:linkScript>
<bs:linkCSS>
  /css/admin/buildTypeForm.css
  /css/artifactsStorage.css
</bs:linkCSS>

<div id="ArtifactStorages" class="section noMargin">
<ext:extensionsAvailable placeId="<%=PlaceId.EDIT_PROJECT_STORAGE_LIST_TOOLS%>">
  <div id="storage_tools_list">
    <ext:includeExtensions placeId="<%=PlaceId.EDIT_PROJECT_STORAGE_LIST_TOOLS%>">
      <jsp:attribute name="separator"><div class="divider"></div></jsp:attribute>
    </ext:includeExtensions>
  </div>
</ext:extensionsAvailable>

  <h2 class="noBorder">Artifacts storage</h2>
  <bs:smallNote>
    On this page you can define how TeamCity stores and accesses artifacts produced by builds of this project and its subprojects.
  </bs:smallNote>
  <input type="hidden" id="projectId" name="projectId" value="${project.externalId}"/>
  <%--@elvariable id="availableSettings" type="java.util.List<jetbrains.buildServer.serverSide.storage.ArtifactsStorageSettingsBean>"--%>
  <%--@elvariable id="resetSettings" type="jetbrains.buildServer.serverSide.storage.ArtifactsStorageSettingsBean"--%>
  <c:set var="canEdit" value="${afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}"/>
  <c:if test="${not project.readOnly and canEdit}">
    <p style="margin-top: 0">
      <forms:addButton href="${pageUrl}&storageSettingsId=NEW_STORAGE&action=edit">Add new storage</forms:addButton>
    </p>
  </c:if>
  <bs:refreshable containerId="storageSettingsList" pageUrl="${pageUrl}">
    <table class="parametersTable">
      <c:if test="${not empty availableSettings}">
        <tr class="header">
          <th colspan="4">Configured artifact storages</th>
        </tr>
        <c:forEach var="storageBean" items="${availableSettings}">
          <tr>
          <c:choose>
            <c:when test="${storageBean.type eq 'DefaultStorage'}">
              <td><c:out value="${storageBean.description}"/></td>
            </c:when>
            <c:when test="${not empty storageBean.sourceProject}">
              <td>
                <c:out value="${storageBean.description}"/>
                <span class="inheritedParam">(inherited from <admin:editProjectLink projectId="${storageBean.sourceProject.externalId}" addToUrl="&tab=artifactsStorage"><c:out value="${storageBean.sourceProject.fullName}"/></admin:editProjectLink>)</span>
              </td>
            </c:when>
            <c:otherwise>
              <td><c:out value="${storageBean.description}"/>
                  <span style="float: right"><a href="" onclick="BS.StorageSettings.showUsagesDialog('<bs:escapeForJs forHTMLAttribute="true" text="${storageBean.description}"/>', '${storageBean.storageSettingsId}'); return false;">Check usages</a></span>
              </td>
            </c:otherwise>
          </c:choose>
          <c:choose>
            <c:when test="${not project.readOnly and not storageBean.isActive and canEdit}">
              <td class="edit"><a href="" onclick="BS.StorageSettings.setActive('${storageBean.storageSettingsId}'); return false;">Make&nbsp;Active</a></td>
            </c:when>
            <c:when test="${(not canEdit or project.readOnly) and not storageBean.isActive}">
              <td class="edit">Inactive</td>
            </c:when>
            <c:when test="${project.readOnly and storageBean.isActive}">
              <td class="edit"><strong>Active</strong></td>
            </c:when>
            <c:otherwise>
              <td class="edit">
                <strong>Active</strong><c:if test="${resetSettings.storageSettingsId ne storageBean.storageSettingsId and canEdit}">&nbsp;(<a href="" onclick="BS.StorageSettings.showResetDialog('${storageBean.storageSettingsId}'); return false;">Reset</a>)</c:if>
              </td>
            </c:otherwise>
          </c:choose>
          <c:choose>
            <c:when test="${storageBean.type eq 'DefaultStorage' or not empty storageBean.sourceProject or not canEdit}">
              <td class="edit" colspan="2">Uneditable</td>
            </c:when>
            <c:when test="${project.readOnly}">
              <td class="edit" colspan="2"><a href="${pageUrl}&storageSettingsId=${storageBean.storageSettingsId}&action=edit">View</a></td>
            </c:when>
            <c:otherwise>
              <td class="edit"><a href="${pageUrl}&storageSettingsId=${storageBean.storageSettingsId}&action=edit">Edit</a></td>
              <td class="edit"><a href="" onclick="BS.StorageSettings.showDeleteDialog('${storageBean.storageSettingsId}', '<bs:escapeForJs forHTMLAttribute="true" text="${storageBean.description}"/>', ${storageBean.usagesCount}); return false;">Delete</a></td>
            </c:otherwise>
          </c:choose>
        </tr>
      </c:forEach>
    </c:if>
  </table>
</bs:refreshable>
</div>
<bs:dialog dialogId="resetConfirmation" title="Are you sure?" closeCommand="BS.resetStorageDialog.close();">
  <div>
    After reset this project will use <c:out value="${resetSettings.description}"/><c:if test="${not empty resetSettings.sourceProject}"> from <admin:editProjectLink projectId="${resetSettings.sourceProject.externalId}" addToUrl="&tab=artifactsStorage"><c:out value="${resetSettings.sourceProject.fullName}"/></admin:editProjectLink></c:if>
  </div>
  <div class="popupSaveButtonsBlock">
    <forms:submit label="Reset" onclick="BS.resetStorageDialog.reset();"/>
    <forms:cancel onclick="BS.resetStorageDialog.close();"/>
  </div>
</bs:dialog>

<bs:dialog dialogId="deleteConfirmation" title="Are you sure?" closeCommand="BS.deleteStorageDialog.close();">
  <div>
    <span id="deleteConfirmationText"></span>
  </div>
  <div class="popupSaveButtonsBlock">
    <forms:submit label="Delete" onclick="BS.deleteStorageDialog.delete();"/>
    <forms:cancel onclick="BS.deleteStorageDialog.close();"/>
  </div>
</bs:dialog>

<bs:dialog dialogId="showSettingsUsages" title="Show Usages" titleId="showSettingsUsagesTitle" closeCommand="BS.storageUsagesDialog.close();">
  <div id="showSettingsUsagesLoading">
    <forms:progressRing className="progressRingInline"/> Looking for usages...
  </div>
  <div id="showSettingsUsagesInner"></div>
  <div class="popupSaveButtonsBlock">
    <forms:cancel label="Close" onclick="BS.storageUsagesDialog.close();"/>
  </div>
</bs:dialog>
