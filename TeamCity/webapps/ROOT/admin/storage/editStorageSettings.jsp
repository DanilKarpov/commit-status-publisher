<%@ page import="jetbrains.buildServer.artifacts.ArtifactStorageSettings" %>
<%@ page import="jetbrains.buildServer.serverSide.storage.ArtifactsStorageSettingsController" %>
<%@ include file="/include-internal.jsp" %>
<bs:linkScript>
  /js/bs/collapseExpand.js
  /js/bs/runningBuilds.js
  /js/bs/blocks.js
  /js/bs/blockWithHandle.js
  /js/bs/blocksWithHeader.js
</bs:linkScript>
<div id="ArtifactStorages" class="section noMargin">
  <h2 class="noBorder">Artifacts storage</h2>
  <bs:smallNote>
  An Artifacts Storage is a set of settings defining how TeamCity stores and accesses binary artifacts produced by builds.
  </bs:smallNote>

  <%--@elvariable id="availableStorages" type="java.util.List<jetbrains.buildServer.serverSide.artifacts.ArtifactStorageType>"--%>
  <%--@elvariable id="selectedStorageType" type="jetbrains.buildServer.serverSide.artifacts.ArtifactStorageType"--%>
  <%--@elvariable id="project" type="jetbrains.buildServer.serverSide.SProject"--%>
  <%--@elvariable id="publicKey" type="java.lang.String"--%>
  <%--@elvariable id="storageSettingsId" type="String"--%>
  <%--@elvariable id="newStorage" type="String"--%>
  <%--@elvariable id="storageSettings" type="jetbrains.buildServer.serverSide.storage.ArtifactsStorageSettingsBean"--%>
  <%--@elvariable id="selectedStorageName" type="String"--%>
  <form id="editStorageForm"
        action="<c:url value='/admin/storageParams.html?projectId=${project.externalId}&storageSettingsId=${storageSettingsId}&newStorage=${Boolean.parseBoolean(newStorage)}'/>"
        method="post" onsubmit="
  <c:choose>
  <c:when test="${empty storageSettings or storageSettings.usagesCount eq 0}">return BS.EditStorageForm.save();</c:when>
  <c:otherwise>return BS.EditStorageForm.confirmSave();</c:otherwise></c:choose>">
    <bs:refreshable containerId="storageParams" pageUrl="${pageUrl}">
      <table class="runnerFormTable">
        <tr>
          <th class="noBorder"><label for="storageType">Storage type:</label></th>
          <td>
            <forms:select name="storageType"
                          onchange="$('storageParams').updateContainer();"
                          enableFilter="true"
                          className="mediumField">
              <c:forEach var="storageType" items="${availableStorages}">
                <forms:option value="${storageType.type}"
                              selected="${selectedStorageType.type == storageType.type}"><c:out value="${storageType.name}"/></forms:option>
              </c:forEach>
            </forms:select>
          </td>
        </tr>
        <tr>
          <th class="noBorder"><label for="storageSettingsId">Storage ID:<l:star/><bs:help file="Entity+IDs"/></label></th>
          <td>
            <c:set var="NEW_STORAGE_ID" value="<%=ArtifactsStorageSettingsController.NEW_STORAGE_ID%>"/>
            <forms:textField name="storageSettingsId"
                             value="${storageSettingsId}"
                             className="longField"
                             disabled="${!NEW_STORAGE_ID.equals(param.storageSettingsId)}"/>
            <span class="smallNote">This ID is used in URLs, REST API, HTTP requests to the server, and configuration settings in the TeamCity Data Directory.</span>
            <span class="error" id="error_storageSettingsId"></span>
          </td>
        </tr>
        <tr>
          <th class="noBorder"><label for="teamcity.storage.name">Storage name:</label></th>
          <td>
            <c:set var="STORAGE_NAME" value="<%=ArtifactStorageSettings.TEAMCITY_STORAGE_NAME_KEY%>"/>
            <forms:textField name="prop:${STORAGE_NAME}" value="${selectedStorageName}" className="longField"/>
            <span class="smallNote">Optional, specify to distinguish this storage settings from others.</span>
          </td>
        </tr>
    <jsp:include page="/admin/storageParams.html">
      <jsp:param name="storageSettings" value="${empty selectedStorageType ? '' : selectedStorageType.type}"/>
      <jsp:param name="storageSettingsId" value="${storageSettingsId}"/>
    </jsp:include>
    </table>
  </bs:refreshable>
  <input type="hidden" id="publicKey" name="publicKey" value="${publicKey}"/>
  <input type="hidden" id="projectId" name="projectId" value="${project.externalId}"/>
  <div class="saveButtonsBlock" id="saveButtons" style="'display:block'}">
    <forms:submit name="submitButton" label="Save"/>
    <forms:cancel onclick="BS.EditStorageForm.close()"/>
    <forms:saving/>
  </div>
</form>
</div>

<script type="text/javascript">
  $j(document).ready(function() {
    BS.AvailableParams.attachPopups('projectId=${project.externalId}', 'buildTypeParams');

    <c:if test="${project.readOnly}">
    BS.EditStorageForm.setReadOnly();
    </c:if>
  });

  $('storageParams').updateContainer = function () {
    var storageTypeValue = $('storageType').getValue();
    $('storageParams').refresh("", "storageType="+ storageTypeValue);
  };
</script>

<c:if test="${not empty storageSettings and storageSettings.usagesCount > 0}">
  <bs:dialog dialogId="editConfirmation" title="Are you sure?" closeCommand="">
    <div>
      Updating settings will affect <a href="" onclick="BS.StorageSettings.showUsagesDialog('<bs:escapeForJs text="${storageSettings.description}" forHTMLAttribute="true"/>', '${storageSettings.storageSettingsId}'); return false;">${storageSettings.usagesCountAsString} usages</a> of <bs:escapeForJs text="${storageSettings.description}" forHTMLAttribute="true"/>.<br/>
      This may cause failures in artifact dependencies resolution.
    </div>
    <div class="popupSaveButtonsBlock">
      <forms:submit label="Save" onclick="BS.EditStorageForm.save()"/>
      <forms:cancel onclick="BS.editStorageDialog.close();"/>
    </div>
  </bs:dialog>
  <bs:dialog dialogId="showSettingsUsages" title="Settings Usages" closeCommand="BS.storageUsagesDialog.close();">
    <div id="showSettingsUsagesLoading">
      <forms:progressRing className="progressRingInline"/> Searching for settings usages...
    </div>
    <div id="showSettingsUsagesInner"></div>
    <div class="popupSaveButtonsBlock">
      <forms:cancel label="Close" onclick="BS.storageUsagesDialog.close();"/>
    </div>
  </bs:dialog>
</c:if>
