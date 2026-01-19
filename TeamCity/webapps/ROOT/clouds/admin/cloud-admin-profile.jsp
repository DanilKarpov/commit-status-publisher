<%@ page import="jetbrains.buildServer.clouds.server.executors.BuildExecutorType" %>
<%@include file="/include-internal.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout" %>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="clouds" tagdir="/WEB-INF/tags/clouds"  %>
<jsp:useBean id="propertiesBean" scope="request" type="jetbrains.buildServer.controllers.BasePropertiesBean"/>
<jsp:useBean id="publicKey" scope="request" type="java.lang.String"/>
<jsp:useBean id="action" scope="request" type="java.lang.String"/>
<jsp:useBean id="form" scope="request" type="jetbrains.buildServer.clouds.server.web.admin.CloudAdminProfileForm"/>
<jsp:useBean id="extensions" scope="request" type="java.util.Collection<jetbrains.buildServer.clouds.CloudTypeExtension>"/>
<jsp:useBean id="postUrl" scope="request" type="java.lang.String"/>
<jsp:useBean id="serverUrl" scope="request" type="java.lang.String"/>
<jsp:useBean id="projectId" scope="request" type="java.lang.String"/>
<jsp:useBean id="cameFromSupport" scope="request" type="jetbrains.buildServer.web.util.CameFromSupport"/>
<jsp:useBean id="terminateConditionsFactory" scope="request" type="jetbrains.buildServer.clouds.server.instances.terminate.TerminateConditionsFactory "/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>

<%-- We have to check this variable, while we have specific code-changes in this JSP for better UX in new UI --%>
<c:set var="ec2CloudReactUiParameter" value="teamcity.internal.ec2.ui.react.enabled"/>
<c:set var="ec2CloudReactUiEnabledGlobal" value="${intprop:getBooleanOrTrue(ec2CloudReactUiParameter)}"/>
<c:set var="ec2CloudReactUiEnabled" value="${project.parameters.getOrDefault(ec2CloudReactUiParameter, ec2CloudReactUiEnabledGlobal)}"/>
<c:set var="newAgentsFormEnabled" value="<%=BuildExecutorType.areExecutorsEnabled(project)%>" />

<c:set var="cameFromUrl" value="<%=cameFromSupport.getCameFromUrl()%>"/>

<c:if test="${empty form.agentData}">
  <c:set var="title">Create New Cloud Profile</c:set>
</c:if>
<c:if test="${not empty form.agentData}">
  <c:set var="title">Edit cloud profile ${fn:escapeXml(form.agentData.profileName)}</c:set>
</c:if>

<c:set var="profileId">
  <c:choose>
    <c:when test="${not empty form.agentData}">
      <c:out value="${form.agentData.profileId}"/>
    </c:when>
    <c:otherwise>
      <c:out value="${null}"/>
    </c:otherwise>
  </c:choose>
</c:set>

<script type="text/javascript">
  var prevItem = BS.Navigation.items[BS.Navigation.items.length-1];
  prevItem.selected = false;
  prevItem.url = '<c:url value="/admin/editProject.html?projectId=${form.projectExtId}&tab=clouds"/>';

  BS.Navigation.items.push({
    title: "<bs:escapeForJs text='${title}'/>",
    url: '${pageUrl}',
    selected: true
  });
  BS.Navigation.writeBreadcrumbs();

  BS.Clouds.Admin.CreateProfileForm.baseParams = function() {
    return "&action=${action}<c:if test="${not empty form.agentData}">&profileId=${profileId}</c:if>";
  };
</script>

<c:set var="hideOldUi" value="${(ec2CloudReactUiEnabled && action == 'edit' && profileId != null && profileId.startsWith('amazon'))?'hidden':''}"/>

<c:set var="ajaxUrl"><c:url value="${postUrl}"/></c:set>


<c:if test="${newAgentsFormEnabled}">
  <div class="newAgentProvider <c:if test="${not empty form.agentData}">grid-types-hidden</c:if>">
    <div class="grid-types-layout">
      <div class="grid-type__header">
        <h1 class="grid-type__header-text">Choose agent provider</h1>
        <div class="grid-type__header-button" id="backToCloudAgentsButton">
          <forms:button href="editProject.html?projectId=${projectId}&tab=clouds">Go back to cloud agents</forms:button>
        </div>
        <div class="grid-type__header-button grid-types-hidden" id="backToProviderPickerButton">
          <forms:button>Go back to a provider picker</forms:button>
        </div>
      </div>
      <div class="grid-types-selector">
        <h3>Offload your tasks to external agents</h3>
        <p>TeamCity will use external agent providers to run builds. It's simpler to configure and should be considered if you're unsure of your needs yet. <a href="https://www.jetbrains.com/help/teamcity/kubernetes-executor.html" class="">Learn more</a></p>
        <div class="types__list">
          <c:forEach items="${form.executorTypes}" var="type">
            <div class="type__item" data-code="<c:out value="${type.getType()}" />">
              <div class="type__item-icon">
                <img src="<c:url value="${type.getProfileIconUrl()}"/>" onerror="this.src='<c:url value="/clouds/img/cloud-types/"/>default.svg'" />
              </div>
              <div class="type__item-name">
                <p><c:out value="${type.displayName}"/></p>
              </div>
              <div class="type__item-description">
                <p><c:out value="${type.getTypeDescription()}"/></p>
              </div>
            </div>
          </c:forEach>
        </div>
      </div>
      <div class="grid-types-selector">
        <h2>Add agents to the project</h2>
        <p>TeamCity will operate agents in your instance based on the conditions you will set. It's more complex to configure tailored for cover more advanced use cases. <a href="https://www.jetbrains.com/help/teamcity/teamcity-integration-with-cloud-solutions.html" class="">Learn more</a></p>
        <div class="types__list">
          <c:forEach items="${form.cloudTypes}" var="type">
            <div class="type__item" data-code="<c:out value="${type.getType()}" />">
              <div class="type__item-icon">
                <img src="<c:url value="${type.getProfileIconUrl()}"/>" onerror="this.src='<c:url value="/clouds/img/cloud-types/"/>default.svg'" />
              </div>
              <div class="type__item-name">
                <p><c:out value="${type.displayName}"/></p>
              </div>
              <div class="type__item-description">
                <p><c:out value="${type.getTypeDescription()}"/></p>
              </div>
            </div>
          </c:forEach>
        </div>
      </div>
    </div>
  </div>
  <style>
    .grid-types-hidden,
    .cloud-type-selector {
      display: none;
    }
  </style>
</c:if>

<div id="newProfileFormDialog" class="cloudProfile <c:if test="${empty form.agentData}">grid-types-hidden</c:if>">
<c:if test="${not empty form.agentData and problems.size() > 0}">
  <div id="cloud-profile-error"></div>
  <script>
  <c:set var="firstProblem" value="${problems.iterator().next()}"/>

  ReactUI.renderCloudProfileError('cloud-profile-error', {
    className: 'cloudProfileError',
    message: `<bs:escapeForJs text="${firstProblem.problemEntry.problem.description}" />`,
    <c:if test="${not empty firstProblem.detailsString}">
      details: `<bs:escapeForJs text="${firstProblem.detailsString}" />`,
    </c:if>
    });
  </script>
</c:if>
<form id="newProfileForm" action="${ajaxUrl}" method="post" onsubmit="return BS.Clouds.Admin.CreateProfileForm.submit();" autocomplete="off">

  <input type="hidden" name="projectId" id="projectId" value="${projectId}" class="ignoreModified"/>
  <table class="runnerFormTable ${hideOldUi}">
  <tr>
    <th><label for="profileName">Profile name:<l:star/></label></th>
    <td>
      <props:textProperty name="profileName" className="longField"/>
      <span id="error_profileName" class="error"></span>
    </td>
  </tr>
  <tr>
    <th><label for="profileDescription">Description:</label></th>
    <td>
      <props:textProperty name="profileDescription" className="longField"/>
      <span id="error_profileDescription"></span>
    </td>
  </tr>
  <tr class="cloud-type-selector">
    <th><label for="cloudType">Cloud type:<l:star/></label></th>
    <td>
      <forms:select name="cloudType" onchange="BS.Clouds.Admin.CreateProfileForm.refreshSelectedCloudType();" className="longField" enableFilter="true">
        <forms:option value="" selected="${empty form.selectedTypeCode}">--- Choose cloud type ---</forms:option>
        <c:forEach items="${form.agentTypes}" var="type">
          <forms:option value="${type.getType()}" selected="${not empty form.selectedTypeCode and type.getType() eq form.selectedTypeCode}"><c:out value="${type.displayName}"/></forms:option>
        </c:forEach>
      </forms:select>
      <forms:saving id="newProviderSaving" className="progressRingInline"/>
      <span class="error" id="error_cloudType"></span>
    </td>
  </tr>
  <tr>
    <th><label for="profileServerUrl">Server URL:</label></th>
    <td>
      <props:textProperty name="profileServerUrl" className="longField"/>
      <span class="error" id="error_profileServerUrl"></span>
      <span class="smallNote">The URL used by cloud agents to connect to the server.</br>If not configured, the default URL is used.<bs:help
          file="Agent+Cloud+Profiles+and+Images"/></span>
    </td>
  </tr>
</table>


  <bs:refreshable containerId="newProfilesContainer" pageUrl="${ajaxUrl}">
    <c:if test="${not empty form.selectedType}">
      <table class="runnerFormTable ${hideOldUi}">
        <tr>
        <tr>
          <th><label for="terminateTimeOut">Terminate instance idle time:</label></th>
          <td>
            <props:textProperty name="terminateTimeOut" className="longField"/>
            <span id="error_terminateTimeOut" class="error"></span>
            <span class="smallNote">Minutes to wait before stopping idle build agent. Leave empty to have no timeout</span>
          </td>
        </tr>
        <tr>
          <th>
            <label>Additional terminate conditions:</label>
          </th>
          <td id="terminateConditionsTd">
            <c:forEach items="${terminateConditionsFactory.getTerminateConditionsFactories(false)}" var="fact">
              <div class="terminateCondition">
              <c:if test="${fact.customizable}">
                <input type="checkbox" id="${fact.code}_checkbox"
                <c:if test="${not empty propertiesBean.properties[fact.code]}">checked="checked"</c:if>
                         onclick="BS.Clouds.Admin.Profile.toggleOption($j(this).is(':checked'), '${fact.code}', '${fact.defaultValue}'); return true;"/>
                <label for="${fact.code}_checkbox"><c:out value="${fact.description}"/></label>
                <props:textProperty name="${fact.code}" style="vertical-align:top;width:50px;">
                    <jsp:attribute name="className">
                      <c:if test="${empty propertiesBean.properties[fact.code]}">hidden</c:if>
                    </jsp:attribute>
                </props:textProperty>
                <c:if test="${not (empty fact.getExtraDescription())}">
                  <div style="margin-left: -40px" class="posRel">

                    <c:out value="${fact.getExtraDescription()}"/>
                  </div>
                </c:if>
              </c:if>
              <c:if test="${not fact.customizable}">
                <props:checkboxProperty name="${fact.code}" value="true"/>
                <label for="${fact.code}"><c:out value="${fact.description}"/></label>
              </c:if>
              </div>
            </c:forEach>
          </td>
        </tr>
      <c:choose>
        <c:when test="${not empty form.editProfileUrl}">
            <jsp:include page="${form.editProfileUrl}"/>
        </c:when>
        <c:otherwise>
          <tr>
            <td colspan="2">
              <bs:smallNote>There are no additional options.</bs:smallNote>
            </td>
          </tr>
        </c:otherwise>
      </c:choose>
      <c:forEach var="ext" items="${extensions}">
        <jsp:useBean id="ext" type="jetbrains.buildServer.clouds.CloudTypeExtension"/>
        <!-- Cloud profile form extension: ${ext} -->
        <jsp:include page="${ext.includeUrl}"/>
        <!-- End of: Cloud profile form extension: ${ext} -->
      </c:forEach>
      </table>
    </c:if>

    <input type="hidden" id="publicKey" name="publicKey" value="${publicKey}"/>
    <input type="hidden" id="action" name="action" value="${action}"/>
    <c:if test="${not empty form.agentData}">
      <input type="hidden" id="profileId" name="profileId" value="${form.agentData.profileId}"/>
    </c:if>
  </bs:refreshable>

  <div class="popupSaveButtonsBlock ${hideOldUi}">
    <input type="hidden" id="cameFromUrl" value="${util:escapeUrlForQuotes(cameFromUrl)}"/>
    <forms:submit label="${form.submitButtonCaption}" id="createButton"/>
    <forms:cancel cameFromSupport="${cameFromSupport}"/>
    <forms:saving id="newProfileProviderProgress"/>
  </div>
  <forms:modified onSave="$j(this.form).submit();"/>
</div>

<c:choose>
  <c:when test="${project.readOnly}">
    <script type="text/javascript">
      $j(document).ready(function() {
        BS.Clouds.Admin.CreateProfileForm.disable();
      });
    </script>
  </c:when>
  <c:otherwise>
    <script type="text/javascript">
      BS.Clouds.Admin.CreateProfileForm.beforeShow('<bs:escapeForJs text="${serverUrl}" />');
      BS.Clouds.Admin.CreateProfileForm.recordInitialParams();

    </script>
  </c:otherwise>
</c:choose>
