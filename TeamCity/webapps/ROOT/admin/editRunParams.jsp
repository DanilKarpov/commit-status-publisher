<%@ page import="jetbrains.buildServer.controllers.ActionMessages" %>
<%@ page import="jetbrains.buildServer.serverSide.impl.runType.ProjectRunType" %>
<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ page import="jetbrains.buildServer.agent.ServerProvidedProperties" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<c:set var="saved" value='<%=ActionMessages.getOrCreateMessages(request).hasMessage("buildRunnerSettingsUpdated")%>'/>

<bs:messages key="buildRunnerSettingsUpdated"/>
<bs:messages key="noRunnersFound"/>

<c:set var="numRunners" value="${fn:length(buildForm.multipleRunnersBean.buildRunners)}"/>

<c:set var="bootstrapParamKey" value="<%= ServerProvidedProperties.BUILD_STEP_PHASE_PARAMETER%>"/>
<c:set var="bootstrapParamValue" value="<%= ServerProvidedProperties.BOOTSTRAP_PHASE%>"/>

<h2 class="noBorder">
  <c:choose>
    <c:when test="${numRunners > 1}">
      <bs:popup_static controlId="configurationSteps" popup_options="shift: {x: -150, y: 20}, className: 'buildStepsPopup quickLinksMenuPopup'">
      <jsp:attribute name="content">
        <l:tableWithHighlighting highlightImmediately="true" className="buildStepsMenu" style="width:100%;">
          <tr>
            <th>Build Steps</th>
          </tr>
          <c:set var="stepno" value="0"/>
          <c:forEach items="${buildForm.multipleRunnersBean.buildRunners}" var="runner">
            <c:set var="stepno" value="${stepno + 1}"/>
            <c:url value='/admin/editRunType.html?init=1&id=${buildForm.settingsId}&runnerId=${runner.id}&cameFromUrl=${util:urlEscape(buildForm.cameFromSupport.cameFromUrl)}'
                   var="onclickUrl"/>
            <tr>
              <td class="highlight" onclick="BS.openUrl(event, '${onclickUrl}')">
                <admin:runnerInfo runner="${runner}" stepno="${stepno}"/>
              </td>
            </tr>
          </c:forEach>
        </l:tableWithHighlighting>
      </jsp:attribute>
        <jsp:body>
          <%--do not reformat the following line--%>
          <span class="pc-title">${buildForm.buildRunnerBean.newRunner ? 'New' : ''} Build Step<c:if
              test="${buildForm.multipleRunnersBean.currentRunnerPosition > 0}"> (${buildForm.multipleRunnersBean.currentRunnerPosition} of
            <a href="<c:url value='/admin/editBuildRunners.html?id=${buildForm.settingsId}'/>" title="Build Steps List">${numRunners}</a>)</c:if>:
          <c:choose>
            <c:when test="${fn:length(buildForm.buildRunnerBean.buildStepName) > 0}">
              <c:set var="buildStepName"><c:out value="${buildForm.buildRunnerBean.buildStepName}"/></c:set>
              <bs:makeBreakable text="${buildStepName}" regex=".{60}" escape="${false}"/>
            </c:when>
            <c:otherwise><c:out value="${buildForm.buildRunnerBean.runType.displayName}"/></c:otherwise>
          </c:choose>
        </span>
        </jsp:body>
      </bs:popup_static>
    </c:when>
    <c:otherwise><span class="pc-title">${buildForm.buildRunnerBean.newRunner ? 'New' : ''} Build Step<c:if
        test="${not empty buildForm.buildRunnerBean.runType.displayName}">:</c:if> <c:out
        value="${buildForm.buildRunnerBean.runType.displayName}"/></span></c:otherwise>
  </c:choose>
</h2>

<p:container contextId="runner_edit_${buildForm.buildRunnerBean.id}" JSObject="BS.EditBuildRunnerForm.Controls">
<jsp:attribute name="content">

  <table class="runnerFormTable">
  <c:choose>

  <c:when test="${intprop:getBoolean('teamcity.ui.classicRunnerSelect')}">
    <tr>
      <th class="noBorder"><label for="runTypeInfoKey">Runner type:</label></th>
      <td class="noBorder">
        <forms:select name="runTypeInfoKey"
                      onchange="BS.updateRunnerContainer();"
                      enableFilter="true"
                      filterOptions="{listMaxVisible:16}"
                      className="mediumField">
          <forms:option value="" selected="${not buildForm.buildRunnerBean.runnerTypeSelected}">-- Choose build runner type --</forms:option>
          <c:if test="${not buildForm.buildRunnerBean.newRunner && buildForm.buildRunnerBean.runnerTypeSelected && not buildForm.buildRunnerBean.isRunTypeAvailable(buildForm.buildRunnerBean.runTypeInfoKey)}">
            <forms:option value="${buildForm.buildRunnerBean.runTypeInfoKey}" selected="${true}">${buildForm.buildRunnerBean.displayName}</forms:option>
          </c:if>
          <c:set var="useGroups" value="${fn:length(buildForm.buildRunnerBean.availableRunTypes) gt 1}"/>
          <c:forEach items="${buildForm.buildRunnerBean.availableRunTypes}" var="it">
            <c:set var="runTypes" value="${it.value}"/>
            <c:choose>
              <c:when test="${useGroups}">
                <optgroup label='<c:out value="${it.key.name}"/>'>
                  <%@ include file="editRunParamsOptions.jspf" %>
                </optgroup>
              </c:when>
              <c:otherwise>
                <%@ include file="editRunParamsOptions.jspf" %>
              </c:otherwise>
            </c:choose>
          </c:forEach>
        </forms:select>
        <forms:saving id="chooseRunnerProgress" className="progressRingInline"/>
        <c:if test="${buildForm.buildRunnerBean.runnerTypeSelected}">
        <c:set var="selectedInfo" value="${buildForm.buildRunnerBean.selectedRunType}"/>
        <span class="smallNote">
          <bs:out value="${selectedInfo.description}"/>
          <c:set var="runType" value="${buildForm.buildRunnerBean.runType}"/>
          <c:set var="ProjectRunType" value="<%=ProjectRunType.class%>"/>
          <c:if test="${ProjectRunType.isAssignableFrom(runType['class'])}">
            <c:set var="ownerProject" value="${runType.ownerProject}"/>
            <c:url var="editRecipeUrl" value="/admin/editProject.html?projectId=${ownerProject.externalId}&tab=recipe&editRecipeId=${runType.type}"/>
            <div style="${fn:length(selectedInfo.description) gt 0 ? 'margin-top: .5em;' : ''}">
              Note: The <a href="${editRecipeUrl}" title="Click to navigate to recipe definition"><c:out value="${runType.displayName}"/></a> recipe is defined in the <admin:editProjectLinkFull
                project="${ownerProject}"/> project.
            </div>
          </c:if>
        </span>
      </c:if>
      </td>
    </tr>
  </c:when>

  <c:otherwise>
    <div id="select-runner-flatten"></div>
    <script>
      (function () {
        <c:set var="selectedInfo" value="${buildForm.buildRunnerBean.selectedRunType}"/>

        ReactUI.renderAdminSelectBuildRunner(document.getElementById('select-runner-flatten'), {
          selectedRunnerKey: "<c:out value="${util:forJS(selectedInfo.key, true, true)}" />",
          projectId: "<c:out value="${util:forJS(buildForm.project.externalId, true, true)}" />",
          <c:if test="${not empty buildForm.readOnlyReason}">
          readOnly: true,
          </c:if>
        });

      })();
    </script>
  </c:otherwise>

  </c:choose>

    <c:if test="${buildForm.buildRunnerBean.runnerTypeSelected && not empty buildForm.buildRunnerBean.deprecationReason}">
    <tr>
      <td class="noBorder" colspan="2">
        <div class="attentionComment"><bs:buildStatusIcon type="red-sign"
                                                          className="warningIcon"/>${buildForm.buildRunnerBean.deprecationReason}<c:if test="${not empty buildForm.buildRunnerBean.deprecationReference}"><bs:help file="${buildForm.buildRunnerBean.deprecationReference}"/></c:if></div>
      </td>
    </tr>
  </c:if>

    <c:if test="${not buildForm.buildRunnerBean.selectedRunType.unknownRunner}">
    <c:if test="${buildForm.buildRunnerBean.runnerTypeSelected}">
      <tr>
        <th class="noBorder"><label for="buildStepName">Step name:</label></th>
        <td>
          <forms:textField name="buildStepName" value="${buildForm.buildRunnerBean.buildStepName}" className="longField"/>
          <span class="smallNote">Optional, specify to distinguish this build step from other steps.</span>
        </td>
      </tr>

      <c:if test="${buildForm.buildRunnerBean.idEditingFeatureEnabled}">
        <tr>
          <th class="noBorder"><label for="buildStepId">Step ID:<l:star/><bs:help file="Entity+IDs"/></label></th>
          <td>
            <forms:textField name="newRunnerId" value="${buildForm.buildRunnerBean.newRunnerId}" className="longField" maxlength="80"
                             disabled="${!buildForm.buildRunnerBean.allowIdEditing}"/>
            <span class="error" id="error_newRunnerId"></span>
            <span class="smallNote">
              This ID is used in URLs, REST API, DSL, HTTP requests to the server, and configuration settings in the TeamCity Data Directory.
              <!--
              It is also useful when you want to refer to the step results via a parameter. -->
              Must be unique across all steps of this configuration.</span>
          </td>
        </tr>
      </c:if>

      <c:if test="${not buildForm.bootstrapStepsEnabled}">
         <props:hiddenProperty name="${bootstrapParamKey}"/>
      </c:if>
      <c:if test="${buildForm.bootstrapStepsEnabled}">
        <tr class="advancedSetting">
          <th class="noBorder"><label for="${bootstrapParamKey}">Run during bootstrap:</label></th>
          <td>
            <label>
              <props:checkboxProperty name="${bootstrapParamKey}" value="${bootstrapParamValue}"/>
              If selected, the step will be run before source checkout
            </label>
          </td>
        </tr>
      </c:if>

      <tr class="advancedSetting">
        <th class="noBorder"><label for="${buildForm.buildRunnerBean.stepExecutionPolicyKey}">Execute step:<bs:help file="Configuring+Build+Steps"/></label></th>
        <td>
          <props:selectProperty name="${buildForm.buildRunnerBean.stepExecutionPolicyKey}" enableFilter="true" className="longField">
            <c:forEach var="p" items="${buildForm.buildRunnerBean.stepExecutionPolicyValues}">
              <props:option value="${p.value}"><c:out value="${p.description}"/></props:option>
            </c:forEach>
          </props:selectProperty>
          <%@ include file="buildStepConditionsList.jspf" %>
        </td>
      </tr>
    </c:if>

    <c:if test="${buildForm.buildRunnerBean.runnerTypeSelected}">

    <input type="hidden" name="publicKey" id="publicKey" value="${buildForm.publicKey}"/> <!-- Should be placed before plugin JSP, otherwise plugin JS code may not be able to access this field -->

    <c:set var="propertiesBean" scope="request" value="${buildForm.buildRunnerBean.propertiesBean}"/>
    <c:set var="includes" value="${buildForm.buildRunnerBean.availableRunnerExtensionUrls}"/>
    <c:choose>
      <c:when test="${not empty includes}">
        <c:forEach var="url" items="${includes}">
          <jsp:include page="${url}"/>
        </c:forEach>
      </c:when>
      <c:otherwise>
        <jsp:include page="/notImplemented.jsp"/>
      </c:otherwise>
    </c:choose>

    <ext:includeExtensions placeId="<%=PlaceId.EDIT_BUILD_RUNNER_SETTINGS_FRAGMENT%>"/>

    <c:if test="${not empty sessionScope['actionErrors']}">
      <jsp:useBean id="actionErrors" type="jetbrains.buildServer.controllers.ActionErrors" scope="session"/>
      <script type="text/javascript">
        <c:forEach items="${actionErrors.errors}" var="error">
        <c:set var="message"><bs:out value='${error.message}'/></c:set>
        BS.EditBuildRunnerForm.showError('${error.id}', '<bs:escapeForJs text='${message}'/>');
        </c:forEach>
        BS.EditBuildRunnerForm.focusFirstErrorField();
      </script>
    </c:if>

    <script type="text/javascript">
      BS.MultilineProperties.updateVisible();
      BS.EditBuildRunnerForm.setModified(${buildForm.buildRunnerBean.stateModified});

      <c:if test="${buildForm.buildRunnerBean.newRunner}">
        {
          const unavailableStepIds = "${buildForm.buildRunnerBean.usedStepIdsString}".split(",");
          BS.BuildRunnerIdGenerator.install(unavailableStepIds);
        }
      </c:if>
    </script>

    </c:if>
  </c:if>
  </table>

  <div class="runners-advanced">
    <admin:showHideAdvancedOpts containerId="editBuildTypeForm" optsKey="buildStepSettings_${buildForm.multipleRunnersBean.currentBuildRunnerBean.runTypeInfoKey}"/>
    <admin:highlightChangedFields containerId="editBuildTypeForm"/>
  </div>

</jsp:attribute>
</p:container>
