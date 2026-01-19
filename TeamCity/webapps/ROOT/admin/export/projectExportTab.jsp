<%@ page import="jetbrains.buildServer.controllers.admin.export.ProjectExportController" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="projectsExport" tagdir="/WEB-INF/tags/admin/projectsExport" %>
<%@ include file="/include-internal.jsp" %>

<bs:linkScript>
  <%--/js/bs/blocks.js--%>
  /js/bs/blockWithHandle.js
  /js/bs/collapseExpand.js
  /js/bs/projectExport.js
</bs:linkScript>

<style type="text/css">
  .usageDetails {
    padding: 0.5em;
  }

  .usageDetailsHeader {
    font-weight: bold;
    padding-bottom: 0.5em;
  }

  .usageDetailsPrefix {
    padding-bottom: 0.5em;
  }

  .collapseExpandBlock {
    margin-bottom: 1em;
    margin-top: 1em;
  }
</style>

<bs:messages key="<%=ProjectExportController.MESSAGE_KEY%>"/>

<div class="section noMargin">
  <h2 class="noBorder">Settings Export</h2>

  <div>
    <div class="successMessage" style="display: none; " id="messageExported">The project is exported.
      You can find the resulting file in the Download directory: <span id="downloadedArchiveName"/> </div>

    <bs:smallNote>
      On this page you can export the project to move it to a different TeamCity server.
    </bs:smallNote>

    <%--@elvariable id="currentProject" type="jetbrains.buildServer.serverSide.SProject"--%>
    <%--@elvariable id="projectsToExport" type="java.util.List"--%>
    <%--@elvariable id="projectDepsReport" type="jetbrains.buildServer.serverSide.projectsExport.ProjectDepsReport"--%>
    The project, its subprojects, and all necessary build configurations, templates and vcs roots defined in the other projects will be exported.<bs:help file="Project+Export"/>

    <div class="collapseExpandBlock">
      <bs:collapseExpand collapseAction="BS.CollapsableBlocks.collapseAll(true, 'projectHierarchy'); return false"
                         expandAction="BS.CollapsableBlocks.expandAll(true, 'projectHierarchy'); return false"/>
    </div>
    <bs:projectHierarchy rootProjects="${projectsToExport}"
                         treeId="exportedProjects"
                         collapsible="true"
                         showProjectDescriptions="false"
                         showBuildTypeDescriptions="false"
                         customEmptyProjectMessage="Project doesn't contain build types, templates and vcs roots">
      <jsp:attribute name="projectHTML"/>
      <jsp:attribute name="buildTypeHTML"/>
        <jsp:attribute name="afterProjectNameHTML">
          <%--@elvariable id="projectBean" type="jetbrains.buildServer.controllers.admin.export.ExportedDependenciesBean"--%>
          <c:choose>
            <c:when test="${projectBean.onlyDefinitionExported}">
              <span class="projectBlockHidden_${projectBean.project.externalId}" <bs:tooltipAttrs
                  text="The project definition (name and desctiption) will be exported only because you don't have edit permissions in the project"/>
                ><bs:buildStatusIcon type="red-sign" className="warningIcon"
              /></span>
            </c:when>
            <c:otherwise>
              <c:if test="${!projectBean.project.rootProject && projectBean.containsNotExportedArtifactDependencies}">
              <span class="projectBlockHidden_${projectBean.project.externalId}" <bs:tooltipAttrs
                  text="The project contains build configurations that will not be exported, expand for the details."/>
                ><bs:buildStatusIcon type="red-sign" className="warningIcon"
              /></span>
            </c:if>
            </c:otherwise>
          </c:choose>
        </jsp:attribute>

        <jsp:attribute name="afterBuildTypeNameHTML">
          <%--@elvariable id="projectBean" type="jetbrains.buildServer.controllers.admin.export.ExportedDependenciesBean"--%>
          <c:choose>
            <c:when test="${!projectBean.exportDecisionForBuildTypes[buildType]}">
              <projectsExport:usageDetails usagePath="${projectDepsReport.usagesPaths[buildType]}" name="${buildType.fullName} build configuration" isWarning="${true}">
                <jsp:attribute name="prefix">
                  The build configuration is used in artifact dependencies only and will not be exported
                </jsp:attribute>
              </projectsExport:usageDetails>
            </c:when>
            <c:otherwise>
              <projectsExport:usageDetails usagePath="${projectDepsReport.usagesPaths[buildType]}" name="${buildType.fullName} build configuration"/>
            </c:otherwise>
          </c:choose>
        </jsp:attribute>

        <jsp:attribute name="afterTemplateNameHTML">
          <projectsExport:usageDetails usagePath="${projectDepsReport.usagesPaths[template]}" name="${template.fullName} template"/>
        </jsp:attribute>

        <jsp:attribute name="afterVcsRootNameHTML">
          <projectsExport:usageDetails usagePath="${projectDepsReport.usagesPaths[vcsRoot]}" name="${vcsRoot.name} vcs root"/>
        </jsp:attribute>

    </bs:projectHierarchy>

    <c:if test="${fn:length(projectDepsReport.buildTypesWithInaccessibleDependencies) > 0 }">

      <div class="attentionComment" style="margin-top: 2em">
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>The following build configurations depend on inaccessible configurations that will not be exported:
        <ul>
          <c:forEach items="${projectDepsReport.buildTypesWithInaccessibleDependencies}" var="bt">
            <li><admin:viewOrEditBuildTypeLinkFull buildType="${bt}" step="dependencies" viewAdditionalParams="&tab=buildTypeSettings"/></li>
          </c:forEach>
        </ul>
      </div>
    </c:if>

    <c:if test="${fn:length(projectDepsReport.buildTypesWithInaccessibleTemplates) > 0 }">

      <div class="attentionComment" style="margin-top: 2em">
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>The following build configurations are based on inaccessible templates that will not be exported:
        <ul>
          <c:forEach items="${projectDepsReport.buildTypesWithInaccessibleTemplates}" var="bt">
            <li><admin:viewOrEditBuildTypeLinkFull buildType="${bt}"/></li>
          </c:forEach>
        </ul>
      </div>
    </c:if>

    <c:if test="${fn:length(projectDepsReport.buildTypesWithInaccessibleVcsRoots) > 0 }">

      <div class="attentionComment" style="margin-top: 2em">
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>The following build configurations use inaccessible vcs roots that will not be exported:
        <ul>
          <c:forEach items="${projectDepsReport.buildTypesWithInaccessibleVcsRoots}" var="bt">
            <li><admin:viewOrEditBuildTypeLinkFull buildType="${bt}" step="vcsRoots"/></li>
          </c:forEach>
        </ul>
      </div>
    </c:if>

    <div class="saveButtonsBlock">
      <c:set var="token"><bs:escapeForJs text="<%=String.valueOf(System.currentTimeMillis())%>"/></c:set>
      <c:url value='/admin/projectExport.html?baseProjectId=${currentProject.externalId}&token=${token}' var="actionUrl"/>
      <a id="startExportBtn" href="${actionUrl}" class="btn btn_primary" onclick="return BS.ExportProjectDialog.startExport('${token}');">Export</a>
      <forms:saving savingTitle="Exporting..."/>
    </div>
  </div>

</div>
