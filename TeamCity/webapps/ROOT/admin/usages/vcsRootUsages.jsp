<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="vcsRoot" type="jetbrains.buildServer.vcs.SVcsRoot" scope="request"/>
<jsp:useBean id="vriMap" type="java.util.Map<jetbrains.buildServer.serverSide.SBuildType, jetbrains.buildServer.vcs.VcsRootInstance>" scope="request"/>
<jsp:useBean id="vriSettingsMap" type="java.util.Map<jetbrains.buildServer.serverSide.SProject, jetbrains.buildServer.vcs.VcsRootInstance>" scope="request"/>
<jsp:useBean id="pipelinesMap" type="java.util.Map<jetbrains.buildServer.serverSide.SProject, jetbrains.buildServer.vcs.VcsRootInstance>" scope="request"/>
<jsp:useBean id="templates" type="java.util.List" scope="request"/>
<jsp:useBean id="totalUsagesNum" type="java.lang.Integer" scope="request"/>
<jsp:useBean id="vcsProblemsBean" type="jetbrains.buildServer.controllers.admin.projects.VcsProblemsBean" scope="request"/>
<c:set value="<%=jetbrains.buildServer.serverSide.systemProblems.StandardSystemProblemTypes.VCS_CONFIGURATION%>" var="problemType"/>

<bs:linkScript>
  /js/bs/systemProblemsMonitor.js
</bs:linkScript>

<h2 class="noBorder">VCS Root <admin:vcsRootName editingScope="editProject:${vcsRoot.project.externalId}" cameFromUrl="${pageUrl}" vcsRoot="${vcsRoot}"/></h2>

<c:if test="${empty templates and empty vriMap and empty vriSettingsMap and totalUsagesNum gt 0}">
  <div class="usagesSection">You do not have enough permissions to see the projects where this VCS root is used.</div>
</c:if>

<c:if test="${totalUsagesNum eq 0}">
  <div class="usagesSection">This VCS root is unused.</div>
</c:if>

<c:if test="${not empty templates}">
  <div class="usagesSection">
    <div>
      Used in <b>${fn:length(templates)}</b> template<bs:s val="${fn:length(templates)}"/>:
    </div>
    <table class="parametersTable">
      <tr>
        <th>
          Build Configuration Template
        </th>
      </tr>

      <c:forEach items="${templates}" var="btSettings" varStatus="pos">
      <tr>
        <td>
          <c:set var="canEdit" value="${afn:permissionGrantedForProject(btSettings.project, 'EDIT_PROJECT')}"/>
          <c:choose>
            <c:when test="${canEdit}">
              <admin:editTemplateLink step="vcsRoots" templateId="${btSettings.externalId}" ><c:out value="${btSettings.fullName}"/></admin:editTemplateLink>
            </c:when>
            <c:otherwise><c:out value="${btSettings.fullName}"/></c:otherwise>
          </c:choose>
        </td>
      </tr>
      </c:forEach>
    </table>
  </div>
</c:if>

<c:if test="${not empty vriMap}">
  <div class="usagesSection">
    <div>
      Used in <b>${fn:length(vriMap)}</b> build configuration<bs:s val="${fn:length(vriMap)}"/>:
    </div>
    <table class="parametersTable">
      <tr>
        <th>
          Build Configuration
        </th>
        <th>
          Commit Hook <bs:help file="Configuring VCS Post-Commit Hooks for TeamCity"/>
        </th>
        <th>
          Latest Check for Changes
        </th>
        <th>
          Changes Checking Interval
        </th>
      </tr>

      <c:set var="lastVri" value="${null}"/>
      <c:forEach items="${vriMap}" var="btVri" varStatus="pos">

        <c:set var="btSettings" value="${btVri.key}"/>
        <c:set var="vri" value="${btVri.value}"/>

        <c:set var="nameTd">
          <td title="VCS root instance ID: ${empty vri ? 'N/A' : vri.id}">

            <c:set var="canEdit" value="${afn:permissionGrantedForBuildType(btSettings, 'EDIT_PROJECT') and (not btSettings.templateBased or btSettings.templateAccessible)}"/>
            <c:choose>
              <c:when test="${canEdit}">
                <admin:editBuildTypeLinkFull step="vcsRoots" buildType="${btSettings}"/>
              </c:when>
              <c:otherwise><c:out value="${btSettings.fullName}"/></c:otherwise>
            </c:choose>

            <bs:systemProblemCountLabel problemsCount="${vcsProblemsBean.problemsCountInfo[vcsRoot].countPerBuildType[btSettings]}"
                                        onclick="BS.SystemProblemsPopup.showDetails('${btSettings.buildTypeId}', '${problemType}', '${vcsRoot.id}', this); return false;"/>
          </td>
        </c:set>

        <%@ include file="processRow.jspf" %>

      </c:forEach>
      <%@ include file="outputVriRows.jspf" %>

    </table>
  </div>
</c:if>

<c:if test="${not empty pipelinesMap}">
  <div class="usagesSection">
    <div>
      Used in <b>${fn:length(pipelinesMap)}</b> pipeline<bs:s val="${fn:length(pipelinesMap)}"/>:
    </div>
    <table class="parametersTable">
      <tr>
        <th>
          Pipelines
        </th>
        <th>
          Commit Hook <bs:help file="Configuring VCS Post-Commit Hooks for TeamCity"/>
        </th>
        <th>
          Latest Check for Changes
        </th>
        <th>
          Changes Checking Interval
        </th>
      </tr>

      <c:set var="lastVri" value="${null}"/>
      <c:forEach items="${pipelinesMap}" var="p">

        <c:set var="proj" value="${p.key}"/>
        <c:set var="vri" value="${p.value}"/>
        <c:set var="canEdit" value="${afn:permissionGrantedForProject(proj, 'EDIT_PROJECT')}"/>

        <c:set var="nameTd">
          <td title="VCS root instance ID: ${empty vri ? 'N/A' : vri.id}">
            <c:choose>
              <c:when test="${canEdit}">
                <admin:pipelineLink edit="true" pipelineId="${proj.externalId}"><c:out value="${proj.name}"/></admin:pipelineLink>
              </c:when>
              <c:otherwise>
                <c:out value="${proj.name}"/>
              </c:otherwise>
            </c:choose>
          </td>
        </c:set>

        <%@ include file="processRow.jspf" %>

      </c:forEach>
      <%@ include file="outputVriRows.jspf" %>

    </table>
  </div>
</c:if>

<c:if test="${not empty vriSettingsMap}">
  <div class="usagesSection">
    <div>
      Used in <b>${fn:length(vriSettingsMap)}</b> project<bs:s val="${fn:length(vriSettingsMap)}"/> to store settings:
    </div>
    <table class="parametersTable">
      <tr>
        <th>
          Project with Versioned Settings
        </th>
        <th>
          Commit Hook <bs:help file="Configuring VCS Post-Commit Hooks for TeamCity"/>
        </th>
        <th>
          Latest Check for Changes
        </th>
        <th>
          Changes Checking Interval
        </th>
      </tr>

      <c:set var="lastVri" value="${null}"/>
      <c:forEach items="${vriSettingsMap}" var="p">

          <c:set var="proj" value="${p.key}"/>
          <c:set var="vri" value="${p.value}"/>
          <c:set var="canEdit" value="${afn:permissionGrantedForProject(proj, 'EDIT_PROJECT')}"/>

          <c:set var="nameTd">
            <td title="VCS root instance ID: ${empty vri ? 'N/A' : vri.id}">
              <c:choose>
                <c:when test="${canEdit}">
                  <admin:editProjectLink projectId="${proj.externalId}" addToUrl="&tab=versionedSettings"><c:out value="${proj.fullName}"/></admin:editProjectLink>
                </c:when>
                <c:otherwise>
                  <c:out value="${proj.fullName}"/>
                </c:otherwise>
              </c:choose>
            </td>
          </c:set>

          <%@ include file="processRow.jspf" %>

      </c:forEach>
      <%@ include file="outputVriRows.jspf" %>

    </table>
  </div>
</c:if>
