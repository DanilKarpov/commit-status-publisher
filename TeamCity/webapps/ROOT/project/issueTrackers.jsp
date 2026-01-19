<%@ include file="/include-internal.jsp"%>

<%--@elvariable id="providers" type="java.util.Map<jetbrains.buildServer.serverSide.SProject, java.util.Map<java.lang.String,jetbrains.buildServer.issueTracker.IssueProviderEx>>"--%>
<%--@elvariable id="myProviders" type="java.util.Map<java.lang.String,jetbrains.buildServer.issueTracker.IssueProviderEx>"--%>
<%--@elvariable id="pageUrl" type="java.lang.String"--%>
<%--@elvariable id="types" type="java.util.Map<java.lang.String, jetbrains.buildServer.issueTracker.IssueProviderType>"--%>
<%--@elvariable id="pluginConfigJsp" type="java.lang.String"--%>
<%--@elvariable id="publicKey" type="java.lang.String"--%>
<%--@elvariable id="project" type="jetbrains.buildServer.serverSide.SProject"--%>
<c:set var="canEdit" value="${afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}"/>
<div class="section noMargin">
  <h2 class="noBorder">Issue Trackers</h2>
  <bs:smallNote>
    This page shows issue tracker connections defined in the current project, as well as connections inherited from parent projects.<bs:help file="Integrating+TeamCity+with+Issue+Tracker"/>
  </bs:smallNote>
  <c:if test="${not project.readOnly and canEdit}">
  <p>
    <forms:addButton onclick="BS.IssueProviderForm.showDialog('${project.externalId}'); return false">Create new connection</forms:addButton>
  </p>
  </c:if>

  <bs:refreshable containerId="providersTable" pageUrl="${pageUrl}">
    <div class="providersListContainer">
      <c:choose>
        <c:when test="${not empty myProviders}">
          <c:set var="editable" value="${not project.readOnly and canEdit}"/>
          <p style="margin-top: 2em">Issue tracker connections defined in the current project:</p>
          <l:tableWithHighlighting id="providers"
                                   className="parametersTable"
                                   mouseovertitle="Click to edit issue tracker connection"
                                   highlightImmediately="true">
            <tr>
              <th colspan="${editable ? 3 : 2}">Issue tracker connections</th>
            </tr>
            <c:set var="currentProject" value="${project}"/>
            <c:forEach items="${myProviders}" var="entry">
              <%@ include file="_issueTrackerDisplay.jspf" %>
            </c:forEach>
          </l:tableWithHighlighting>
        </c:when>
        <c:otherwise>
          <p>There are no issue tracker connections defined in the current project.</p>
        </c:otherwise>
      </c:choose>


      <c:forEach items="${providers}" var="providersEntry">
        <c:if test="${not empty providersEntry.value}" >
          <c:set var="currentProject" value="${providersEntry.key}"/>
          <c:set var="providersCount">${fn:length(providersEntry.value)}</c:set>
          <p style="margin-top: 2em">
            Issue tracker connection<bs:s val="${providersCount}"/> inherited from
            <authz:authorize projectId="${currentProject.externalId}" allPermissions="EDIT_PROJECT" >
            <jsp:attribute name="ifAccessGranted">
              <c:url var="editUrl" value="/admin/editProject.html?projectId=${currentProject.externalId}&tab=issueTrackers"/>
              <a href="${editUrl}"><c:out value="${currentProject.fullName}"/></a>
            </jsp:attribute>
            <jsp:attribute name="ifAccessDenied">
              <bs:projectLink project="${currentProject}"><c:out value="${currentProject.fullName}"/></bs:projectLink>
            </jsp:attribute>
            </authz:authorize>
          </p>
          <table class="parametersTable">
            <tr>
              <th colspan="2">Issue tracker connections</th>
            </tr>
            <c:set var="editable" value="${false}"/>
            <c:forEach var="entry" items="${providersEntry.value}">
              <%@ include file="_issueTrackerDisplay.jspf" %>
            </c:forEach>
          </table>
        </c:if>
      </c:forEach>
    </div>
  </bs:refreshable>
</div>

<bs:modalDialog formId="newIssueProviderForm"
                title="Create New Issue Tracker Connection"
                action="#"
                closeCommand="BS.IssueProviderForm.close();"
                saveCommand="BS.IssueProviderForm.submit();">
  <table class="editProviderTable">
    <tr>
      <th><label for="providerType" class="shortLabel">Connection Type:</label></th>
      <td>
        <forms:select name="providerType" onchange="BS.IssueProviderForm.refreshDialog('${pageUrl}');" enableFilter="true">
          <option value="" id="noType">--- Choose the type ---</option>
          <c:forEach items="${types}" var="typeEntry">
            <option value="${typeEntry.key}">${typeEntry.value.displayName}</option>
          </c:forEach>
        </forms:select>
        <forms:saving id="newProviderSaving" className="progressRingInline"/>
      </td>
    </tr>
  </table>

  <bs:refreshable containerId="newIssueProviderContainer" pageUrl="">
    <div id="newProviderDiv">
      <c:if test="${not empty pluginConfigJsp}">
        <jsp:include page="${pluginConfigJsp}"/>
      </c:if>
    </div>
    <input type="hidden" name="publicKey" value="${publicKey}"/>
  </bs:refreshable>

  <div class="popupSaveButtonsBlock">
    <forms:submit label="Create" id="createButton"/>
    <forms:submit label="Test connection" id="connectionButtonNew"
                  onclick="BS.IssueProviderForm.testConnection(); return false;"/>
    <forms:cancel onclick="BS.IssueProviderForm.cancelDialog()" showdiscardchangesmessage="false"/>
    <forms:saving id="newIssueProviderProgress"/>
  </div>
</bs:modalDialog>

<bs:modalDialog formId="editIssueProviderForm"
                title="Edit Issue Tracker Connection"
                action="#"
                closeCommand="BS.EditIssueProviderForm.close();"
                saveCommand="BS.EditIssueProviderForm.submit();">
  <bs:refreshable containerId="editIssueProviderContainer" pageUrl="">
    <div id="editProviderDiv"></div>
    <input type="hidden" name="publicKey" value="${publicKey}"/>
  </bs:refreshable>

  <div class="popupSaveButtonsBlock">
    <forms:submit label="Save" id="saveProvider"/>
    <forms:submit label="Test connection" id="connectionButtonEdit"
                  onclick="BS.EditIssueProviderForm.testConnection(); return false;"/>
    <forms:cancel onclick="BS.EditIssueProviderForm.cancelDialog()" showdiscardchangesmessage="false"/>
    <forms:saving id="editIssueProviderProgress"/>
  </div>
</bs:modalDialog>

<bs:modalDialog formId="testConnection"
                title="Test connection"
                action="#"
                closeCommand="BS.IssueProviderTestConnection.cancelDialog();"
                saveCommand="">

  <label for="issueId" class="tableLabel" style="width: 6em;">Issue id:</label>
  <forms:textField id="issueId" value="" defaultText="" name="issueId" className="mediumField"/>
  <div class="clr"></div>

  <div id="issueDetails"></div>
  <div class="popupSaveButtonsBlock">
    <forms:submit label="Test"
                  onclick="BS.IssueProviderTestConnection.testConnection(); return false;"/>
    <forms:cancel onclick="BS.IssueProviderTestConnection.cancelDialog()"/>
    <forms:saving id="testConnectionProgress" className="progressRingInline"/>
  </div>
</bs:modalDialog>
<script type="text/javascript">
  (function() {
    var parsedHash = BS.Util.paramsFromHash('&');
    if (parsedHash['addTracker']) {
      BS.Util.setParamsInHash({}, '&', true);
      BS.IssueProviderForm.showDialog('${project.externalId}', parsedHash);
    } else if (parsedHash['editTracker']) {
      BS.Util.setParamsInHash({}, '&', true);
      BS.EditIssueProviderForm.showEdit('${project.externalId}', parsedHash, ${editable});
    }
  })();
</script>
