<%@include file="/include-internal.jsp"%>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<c:set var="progressId" value="settingsPersistErrorsProgress_${showMode}"/>
<c:set var="detailsId" value="settingsPersistErrorsDetails_${showMode}"/>
<c:set var="buttonId" value="settingsPersistErrorsButton_${showMode}"/>
<c:set var="projectErrors" value="${healthStatusItem.additionalData['projectErrors']}"/>
<c:set var="buildTypeErrors" value="${healthStatusItem.additionalData['buildTypeErrors']}"/>
<c:set var="templateErrors" value="${healthStatusItem.additionalData['templateErrors']}"/>
<c:set var="vcsRootErrors" value="${healthStatusItem.additionalData['vcsRootErrors']}"/>
<c:set var="fileErrors" value="${healthStatusItem.additionalData['fileErrors']}"/>
<%--@elvariable id="projectErrors" type="java.util.Map<jetbrains.buildServer.serverSide.SProject,java.lang.String>"--%>
<%--@elvariable id="buildTypeErrors" type="java.util.Map<jetbrains.buildServer.serverSide.SBuildType,java.lang.String>"--%>
<%--@elvariable id="templateErrors" type="java.util.Map<jetbrains.buildServer.serverSide.BuildTypeTemplate,java.lang.String>"--%>
<%--@elvariable id="vcsRootErrors" type="java.util.Map<jetbrains.buildServer.vcs.SVcsRoot,java.lang.String>"--%>
<%--@elvariable id="fileErrors" type="java.util.Map<jetbrains.buildServer.serverSide.SProject,java.util.Map<java.lang.String,java.lang.String>>"--%>
<style type="text/css">
  .errorBlock {
    margin-left: 1em;
  }
</style>
<c:set var="showAdminAction" value="${afn:permissionGrantedForProjectWithId('_Root', 'EDIT_PROJECT') || afn:permissionGrantedGlobally('EDIT_PROJECT') || afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}"/>
<c:if test="${showAdminAction}">
  <script type="text/javascript">
    resolvePersistErrors_${showMode} = function() {
      $j('#${progressId}').show();
      $j('#${buttonId}').prop("disabled",true);
      BS.ajaxRequest(window['base_uri'] + '/admin/action.html', {
        parameters: Object.toQueryString({resolvePersistErrors: 'true'}),
        onComplete: function(transport) {
          document.location.reload();
        }
      });
    };
  </script>
</c:if>
TeamCity failed to persist settings on disk
<c:if test="${showAdminAction}">
<input type="button" id="${buttonId}" class="btn btn_mini" value="Persist" onclick="resolvePersistErrors_${showMode}()"/>
<forms:saving id="${progressId}" style="float: none; margin-left: 0.5em;"/>
</c:if>

<div><a href="javascript:;" onclick="$j('#${detailsId}').toggle();">Show details &raquo;</a></div>
<div id="${detailsId}" style="display: none">
  <c:if test="${not empty projectErrors}">
    <div>${fn:length(projectErrors)} <bs:plural txt="Project" val="${fn:length(projectErrors)}"/> affected:</div>
    <c:forEach items="${projectErrors}" var="error">
      <div>
        <admin:editProjectLink projectId="${error.key.externalId}"><admin:projectName project="${error.key}"/></admin:editProjectLink>
        <div class="errorBlock"><c:out value="${error.value}"/></div>
      </div>
    </c:forEach>
  </c:if>

  <c:if test="${not empty buildTypeErrors}">
    <div>${fn:length(buildTypeErrors)} <bs:plural txt="Build Configuration" val="${fn:length(buildTypeErrors)}"/> affected:</div>
    <c:forEach items="${buildTypeErrors}" var="error">
      <div>
        <admin:editBuildTypeLink buildTypeId="${error.key.externalId}"><c:out value="${error.key.name}"/></admin:editBuildTypeLink>
        <div class="errorBlock"><c:out value="${error.value}"/></div>
      </div>
    </c:forEach>
  </c:if>

  <c:if test="${not empty templateErrors}">
    <div>${fn:length(templateErrors)} <bs:plural txt="Build Configuration Template" val="${fn:length(templateErrors)}"/> affected:</div>
    <c:forEach items="${templateErrors}" var="error">
      <div>
        <admin:editTemplateLink templateId="${error.key.externalId}"><c:out value="${error.key.name}"/></admin:editTemplateLink>
        <div class="errorBlock"><c:out value="${error.value}"/></div>
      </div>
    </c:forEach>
  </c:if>

  <c:if test="${not empty vcsRootErrors}">
    <div>${fn:length(vcsRootErrors)} <bs:plural txt="VCS Root" val="${fn:length(vcsRootErrors)}"/> affected:</div>
    <c:forEach items="${vcsRootErrors}" var="error">
      <div>
        <admin:editVcsRootLink vcsRoot="${error.key}" editingScope="none" cameFromUrl="${pageUrl}"><c:out value="${error.key.name}"/></admin:editVcsRootLink>
        <div class="errorBlock"><c:out value="${error.value}"/></div>
      </div>
    </c:forEach>
  </c:if>

  <c:if test="${not empty fileErrors}">
    <div>Files in ${fn:length(fileErrors)} <bs:plural txt="Project" val="${fn:length(fileErrors)}"/> affected:</div>
    <c:forEach items="${fileErrors}" var="projectFileErrors">
      <div>
        <admin:editProjectLink projectId="${projectFileErrors.key.externalId}"><admin:projectName project="${projectFileErrors.key}"/></admin:editProjectLink>
        <c:forEach items="${projectFileErrors.value}" var="fileError">
          <div><c:out value="${fileError.key}"/></div>
          <div class="errorBlock"><c:out value="${fileError.value}"/></div>
        </c:forEach>
      </div>
    </c:forEach>
  </c:if>
</div>