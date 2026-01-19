<%@ page import="jetbrains.buildServer.controllers.admin.projects.VcsPropertiesBean" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<%@ taglib prefix="admfn" uri="/WEB-INF/functions/admin" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<jsp:useBean id="pageUrl" type="java.lang.String" scope="request"/>
<c:set var="vcsRootsBean" value="${buildForm.vcsRootsBean}"/>
<admin:editBuildTypePage selectedStep="vcsRoots">
  <jsp:attribute name="body_include">
    <c:url value='/admin/editBuildTypeVcsRoots.html?id=${buildForm.settingsId}&doAttach=true&submitBuildType=store' var="attachLink"/>
    <c:url value='/admin/editBuildTypeVcsRoots.html?init=1&id=${buildForm.settingsId}' var="vcsRootsLink"/>

    <admin:vcsRootEditScope vcsRootsBean="${vcsRootsBean}" vcsRoot="${null}" buildForm="${buildForm}"/>
    <c:set var="createLink"><admin:createVcsRootLink editingScope="${editingScope}"
                                                     cameFromTitle="Edit Build Configuration${buildForm.template ? ' Template' : ''}"
                                                     cameFromUrl="${pageUrl}"
                                                     withoutLink="true"/></c:set>

    <c:set var="attachableRoots" value="${vcsRootsBean.attachableVcsRoots}"/>
    <c:set var="popularRoots" value="${vcsRootsBean.popularVcsRoots}"/>

    <table class="runnerFormTable" style="width: 80%;">
      <c:if test="${not empty attachableRoots}">
        <tr>
          <th class="noBorder">
            <label for="vcsRootId">Attach existing VCS root:</label>
          </th>
          <td class="noBorder">
            <admin:vcsRootChooser chooserName="vcsRootId" headerOption="-- Choose VCS root to attach --" popularRoots="${popularRoots}" attachableRoots="${attachableRoots}" onchange="attachExistingVcsRoot('${attachLink}')"/>
          </td>
        </tr>
      </c:if>
      <authz:authorize projectId="${buildForm.project.projectId}" anyPermission="CREATE_DELETE_VCS_ROOT">
        <tr>
          <th class="noBorder">
            <label for="vcsRootType">Create new VCS root:</label>
          </th>
          <td class="noBorder">
            <forms:select name="vcsName" enableFilter="true" className="longField" onchange="if (this.selectedIndex > 0) openCreateRootPage('${createLink}')">
              <forms:option value="">-- Choose VCS root type --</forms:option>
              <forms:option value="<%=VcsPropertiesBean.AUTO_DETECT_NAME%>">&lt;Guess settings from repository URL&gt;</forms:option>
              <c:forEach items="${vcsRootsBean.availableVcsTypes}" var="vcsType">
                <forms:option value="${vcsType.name}"><c:out value="${vcsType.displayName}"/></forms:option>
              </c:forEach>
            </forms:select>
          </td>
        </tr>
      </authz:authorize>
    </table>

    <br/>

    <script type="text/javascript">
      function openCreateRootPage(createLink) {
        var vcsName = $('vcsName').options[$('vcsName').selectedIndex].value;
        if (vcsName == '') return;

        document.location.href = createLink + '&vcsName=' + vcsName;
      }

      function attachExistingVcsRoot(attachLink) {
        var vcsRootId = $('vcsRootId').options[$('vcsRootId').selectedIndex].value;
        if (vcsRootId == '') return;

        BS.VcsRootsUtil.attachVcsRoot('${buildForm.settingsId}', vcsRootId);
      }
    </script>

  </jsp:attribute>

</admin:editBuildTypePage>
