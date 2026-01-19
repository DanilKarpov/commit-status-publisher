<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<%@ taglib prefix="admfn" uri="/WEB-INF/functions/admin" %>
<jsp:useBean id="vcsRootsForm" type="jetbrains.buildServer.controllers.admin.projects.ProjectVcsRootsBean" scope="request"/>

<bs:linkScript>
  /js/bs/systemProblemsMonitor.js
</bs:linkScript>

<c:set value="<%=jetbrains.buildServer.serverSide.systemProblems.StandardSystemProblemTypes.VCS_CONFIGURATION%>" var="problemType"/>
<c:set var="vcsProblemsBean" value="${vcsRootsForm.vcsProblemsBean}"/>
<c:set var="visibleVcsRoots" value="${vcsRootsForm.visibleVcsRoots}"/>
<c:set var="formHasFilter" value="${not empty vcsRootsForm.keyword or vcsRootsForm.showUnusedOnly or vcsRootsForm.showSubProjectsVcsRoots}"/>
<div id="existingVcsRoots" class="section noMargin">
  <h2 class="noBorder">VCS Roots</h2>
  <bs:smallNote>A VCS Root is a set of settings defining how TeamCity communicates with a version control system to monitor changes and get sources of a build<bs:help file="VCS+Root"/></bs:smallNote>

  <c:set var="cameFromUrl" value="${param['cameFromUrl']}"/>
  <c:if test="${not currentProject.readOnly}">
  <authz:authorize projectId="${vcsRootsForm.ownerProjectId}" anyPermission="CREATE_DELETE_VCS_ROOT">
    <p style="margin-top: 0">
      <admin:createVcsRootLink editingScope="editProject:${vcsRootsForm.ownerProjectExternalId}" cameFromUrl="${cameFromUrl}" cameFromTitle="">Create VCS root</admin:createVcsRootLink>
    </p>
  </authz:authorize>
  </c:if>

  <bs:messages key="vcsRootRemoved"/>
  <bs:messages key="vcsRootsUpdated"/>
  <bs:messages key="vcsRootDetached"/>
  <bs:messages key="vcsRootAttached"/>
  <bs:messages key="vcsRootUpdateFailure"/>
  <bs:messages key="tokenInfo"/>

  <form action="<c:url value='/admin/editProject.html'/>" method="get" id="vcsRootsFilterForm">
    <div class="actionBar">
      <span class="nowrap">
        <label class="firstLabel" for="keyword">Filter: </label>
        <forms:textField name="keyword" value="${vcsRootsForm.keyword}" size="20"/>
      </span>

      <forms:filterButton/>
      <c:if test="${not empty vcsRootsForm.keyword}">
        <forms:resetFilter resetHandler="$('vcsRootsFilterForm').keyword.value='';$('vcsRootsFilterForm').submit();"/>
      </c:if>

      <span style="margin-left: 20px">
        <forms:checkbox name="showSubProjectsVcsRoots" checked="${vcsRootsForm.showSubProjectsVcsRoots}" onclick="if (!this.checked) { $j('#showArchivedSubProjectsVcsRoots').prop('checked', ''); } $('vcsRootsFilterForm').submit();"/>
        <label for="showSubProjectsVcsRoots" style="margin: 0;">Show VCS roots from subprojects</label>
      </span>

      <span style="margin-left: 5px">
        (<forms:checkbox name="showArchivedSubProjectsVcsRoots" checked="${vcsRootsForm.showArchivedSubProjectsVcsRoots}" onclick="if (this.checked) { $j('#showSubProjectsVcsRoots').prop('checked', 'checked'); } $('vcsRootsFilterForm').submit();"/>
        <label for="showArchivedSubProjectsVcsRoots" style="margin: 0;">including archived</label>)
      </span>

      <span style="margin-left: 20px">
        <forms:checkbox name="showUnusedOnly" checked="${vcsRootsForm.showUnusedOnly}" onclick="$('vcsRootsFilterForm').submit();"/>
        <label for="showUnusedOnly" style="margin: 0;">Show unused VCS roots only</label>
      </span>

    </div>
    <input type="hidden" name="projectId" value="${vcsRootsForm.ownerProjectExternalId}"/>
    <input type="hidden" name="tab" value="projectVcsRoots"/>
  </form>

  <div>
    Found <strong>${vcsRootsForm.pager.totalRecords}</strong> VCS root<bs:s val="${vcsRootsForm.pager.totalRecords}"/>
  </div>

  <c:if test="${not empty visibleVcsRoots}">
    <l:tableWithHighlighting className="parametersTable" id="projectVcsRoots" highlightImmediately="true">
      <tr>
        <c:if test="${vcsRootsForm.showSubProjectsVcsRoots}"><th>Project</th></c:if>
        <th colspan="3">VCS Root</th>
      </tr>
      <c:set var="prevProject" value="${null}"/>
      <c:set var="visibleVcsRootsMap" value="${vcsRootsForm.visibleVcsRootsMap}"/>
      <c:forEach items="${visibleVcsRoots}" var="vcsRoot" varStatus="status">
        <c:set var="rootProject" value="${vcsRoot.project}"/>
        <c:set var="canDeleteRoot" value="${not empty rootProject and afn:permissionGrantedForProject(rootProject, 'CREATE_DELETE_VCS_ROOT')}"/>
        <c:set var="canEditRoot" value="${afn:canEditVcsRoot(vcsRoot)}"/>
        <c:choose>
          <c:when test="${not empty vcsRootsForm.ownerProjectExternalId}"><c:set var="editingScope">editProject:${vcsRootsForm.ownerProjectExternalId}</c:set></c:when>
          <c:when test="${not empty rootProject}"><c:set var="editingScope">editProject:${rootProject.externalId}</c:set></c:when>
          <c:otherwise><c:set var="editingScope">none</c:set></c:otherwise>
        </c:choose>
        <c:set var="editVcsRootLink"><admin:editVcsRootLink editingScope="${editingScope}"
                                                            vcsRoot="${vcsRoot}"
                                                            withoutLink="true"
                                                            cameFromUrl="${cameFromUrl}"
                                                            cameFromTitle="Edit Project"/></c:set>
        <c:set var="onclick">BS.openUrl(event, '${editVcsRootLink}');</c:set>

        <c:set var="vcsRootUsed" value="${vcsRootsForm.usagesMap[vcsRoot]}"/>
        <c:url value='/admin/editProject.html?tab=usagesReport&projectId=${vcsRoot.project.externalId}&vcsRootId=${vcsRoot.externalId}' var="vcsRootUsages"/>

        <tr>
          <c:if test="${vcsRootsForm.showSubProjectsVcsRoots and prevProject ne rootProject}">
            <td rowspan="${fn:length(visibleVcsRootsMap[rootProject])}"
            ><admin:editProjectLinkFull project="${vcsRoot.project}" contextProject="${currentProject}"/><c:if test="${vcsRoot.project.archived}"><span class="archived_project"> archived</span></c:if></td>
          </c:if>
          <td class="highlight beforeActions" onclick="${onclick}">
            <span class="smallNote" style="float: right; white-space: nowrap;">
              <span id="vcsRootProgress_${vcsRoot.externalId}" style="display: none; padding-left: 2em;"><forms:saving id="vcsRootProgress_${vcsRoot.externalId}:img" className="progressRingInline"/> Saving...</span>
            </span>

            <span class="vcsRoot">
              <admin:vcsRootName editingScope="${editingScope}" cameFromUrl="${pageUrl}" vcsRoot="${vcsRoot}"/>
            </span>

            <span style="float: right; padding-left: 2em; padding-right: 1em;">
              <c:if test="${not vcsRootUsed}"><em>(unused)</em></c:if>
              <c:if test="${vcsRootUsed}"><a href="${vcsRootUsages}">View usages</a></c:if>
            </span>

            <span style="float: right">
               <bs:systemProblemCountLabel problemsCount="${vcsProblemsBean.problemsCountInfo[vcsRoot].totalProblemsCount}" onclick="document.location.href='${vcsRootUsages}'"/>
            </span>

            <div class="clearfix"></div>
          </td>
          <td class="edit highlight" onclick="${onclick}">
              <a href="${editVcsRootLink}">${(not canEditRoot) or vcsRoot.readOnly ? 'View' : 'Edit'}</a>
          </td>
          <td class="edit highlight">
            <c:choose>
              <c:when test="${canDeleteRoot and !rootProject.readOnly and not vcsRootUsed}"><a href="#" onclick="BS.AdminActions.deleteVcsRoot('${vcsRoot.externalId}', '${util:forJS(vcsRoot.name, true, true)}'); return false">Delete</a></c:when>
              <c:when test="${not canDeleteRoot}">
                <span title="VCS root cannot be deleted, because you do not have enough permissions">undeletable</span>
              </c:when>
              <c:when test="${rootProject.readOnly}">
                <span title="VCS root cannot be deleted, because VCS root project is in read only mode">undeletable</span>
              </c:when>
              <c:otherwise>
                <span title="VCS root cannot be deleted, because it has some usages">undeletable</span>
              </c:otherwise>
            </c:choose>
          </td>
        </tr>
        <c:set var="prevProject" value="${rootProject}"/>
      </c:forEach>
    </l:tableWithHighlighting>
  </c:if>

  <bs:pager place="bottom"
            urlPattern="editProject.html?tab=projectVcsRoots&projectId=${vcsRootsForm.ownerProjectExternalId}&page=[page]&keyword=${vcsRootsForm.keyword}&showUnusedOnly=${vcsRootsForm.showUnusedOnly}&showSubProjectsVcsRoots=${vcsRootsForm.showSubProjectsVcsRoots}&showArchivedVcsRoots=${vcsRootsForm.showArchivedSubProjectsVcsRoots}"
            pager="${vcsRootsForm.pager}"/>
</div>
