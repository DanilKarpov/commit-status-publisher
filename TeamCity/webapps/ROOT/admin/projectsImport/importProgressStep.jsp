<%@ include file="/include-internal.jsp" %>
<%--@elvariable id="importProgressStep" type="jetbrains.buildServer.controllers.admin.projectsImport.ImportProgressStepBean"--%>

<h2>Import Status</h2>
<table class="runnerFormTable">
  <tr>
    <th><label>Importing from:</label></th>
    <td>
      <div>${importProgressStep.importedArchive.path} (${util:formatFileSize(importProgressStep.importedArchive.sizeInBytes,2)})</div>
    </td>
  </tr>
  <tr>
    <th><label>Time spent:</label></th>
    <td>
      <div><bs:printTime time="${importProgressStep.spentTime / 1000}"/>
        <c:if test="${not importProgressStep.finished}"><span title="Running..."><bs:buildStatusIcon type="running-green"/></span></c:if>
      </div>
    </td>
  </tr>
  <c:if test="${importProgressStep.finished}">
    <c:set value="${fn:length(importProgressStep.importedProjects)}" var="importedProjectsCount"/>
    <tr>
      <th><label>Import finished:</label></th>
      <td>
        <c:choose>
          <c:when test="${importedProjectsCount == 0}">
            <div>No projects were imported.</div>
          </c:when>
          <c:otherwise>
            <div>Data for <strong>${importedProjectsCount}</strong> project<bs:s val="${importedProjectsCount}"/> has been imported:</div>
            <div class="multi-select projectTree">
              <c:forEach items="${importProgressStep.importedProjects}" var="bean">
                <%--@elvariable id="bean" type="jetbrains.buildServer.web.util.ProjectHierarchyBean"--%>
                <c:set var="project" value="${bean.project}"/>
                <%--@elvariable id="project" type="jetbrains.buildServer.serverSide.SProject"--%>
                <div class="user-depth-${bean.limitedDepth}">
                  <bs:projectOrBuildTypeIcon type="project"/><bs:projectLink project="${project}"/>
                </div>
              </c:forEach>
            </div>
          </c:otherwise>
        </c:choose>

        <c:set var="numErrors" value="${importProgressStep.log.numberOfErrors}"/>
        <c:set var="numWarns" value="${importProgressStep.log.numberOfWarnings}"/>
        <c:if test="${numErrors > 0 || numWarns > 0}">
          <div>
            There <c:if test="${numErrors > 0}"><bs:were_was val="${numErrors}"/> <span class="status_err"><strong>${numErrors}</strong> error<bs:s
              val="${numErrors}"/></span><c:if test="${numWarns > 0}"> and </c:if></c:if
              ><c:if test="${numWarns > 0}"><c:if test="${numErrors == 0}"><bs:were_was val="${numWarns}"/></c:if> <strong>${numWarns}</strong> warning<bs:s
              val="${numWarns}"/></c:if>.
          </div>
        </c:if>

        <c:if test="${importedProjectsCount > 0}">
          <div>Build logs and artifacts are not imported automatically. See <bs:helpLink file="ProjectImport-MovingArtifactsAndLogs">documentation</bs:helpLink>
            for details how to import them.
          </div>
        </c:if>
      </td>
    </tr>
  </c:if>
</table>

<h3>Import log:</h3>

<div class="report">
  <c:forEach items="${importProgressStep.log.messages}" var="message">
    <div class="${message.status.htmlClass}">[<bs:date value="${message.date}" pattern="HH:mm:ss"/>]: <c:out value="${message.text}"/></div>
  </c:forEach>
  <c:if test="${!importProgressStep.finished}">
    <bs:buildStatusIcon type="running-green"/>Running...
  </c:if>
</div>

<c:choose>
  <c:when test="${importProgressStep.finished}">
    <div class="saveButtonsBlock">
      <forms:submit label="Start New Import" onclick="BS.ProjectsImport.cancelCurrentTask();"/>
    </div>
  </c:when>
  <c:otherwise>
    <script type="text/javascript">
      BS.ProjectsImport.scheduleRefresh();
    </script>
  </c:otherwise>
</c:choose>
