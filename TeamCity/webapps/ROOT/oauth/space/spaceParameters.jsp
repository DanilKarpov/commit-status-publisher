<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ page import="java.util.UUID" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceAccessTokenController" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceApplicationController" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceConstants" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.OAuthConstants" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceFeatures" %>

<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout" %>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="keys" class="jetbrains.buildServer.serverSide.oauth.space.SpaceOAuthKeys"/>
<jsp:useBean id="oauthConnectionBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthProvider" scope="request"/>
<jsp:useBean id="rootUrl" type="java.lang.String" scope="request"/>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>

<%--@elvariable id="redirectUrl" type="java.lang.String"--%>
<%--@elvariable id="redirectUrlUnique" type="java.lang.String"--%>
<%--@elvariable id="redirectUrlFallback" type="java.lang.String"--%>
<%--@elvariable id="isNewConnection" type="java.lang.Boolean"--%>

<c:set var="currentRootUrl" value="${WebUtil.getRootUrl(pageContext.request)}"/>
<c:set var="currentSpaceRootUrl" value="${WebUtil.getRootUrl(pageContext.request)}${SpaceAccessTokenController.PATH}"/>
<c:set var="spaceRootUrl" value="${rootUrl}${SpaceAccessTokenController.PATH}"/>
<c:set var="currentSpaceApplicationUrl" value="${SpaceApplicationController.PATH}"/>
<c:set var="newConnection" value="${empty oauthConnectionBean.connectionId}"/>
<c:set var="displayNameParam" value="<%=OAuthConstants.DISPLAY_NAME_PARAM%>"/>
<c:set var="defaultDisplayName" value="${oauthConnectionBean.defaultProperties[displayNameParam]}"/>
<c:set var="spaceFeatures" value="<%=SpaceFeatures.forScope(project)%>"/>
<c:set var="paramUseUniqueRedirect" value="<%=OAuthConstants.PARAM_USE_UNIQUE_REDIRECT%>"/>
<c:set var="paramRedirectId" value="<%=OAuthConstants.PARAM_REDIRECT_ID%>"/>

<c:set var="idManualHint" value="manualHint"/>
<c:set var="idOrganizationHint" value="organizationHint"/>
<c:set var="idProjectHint" value="projectHint"/>
<c:set var="idCreationModeSelect" value="creationModeSelect"/>
<c:set var="idCreationModeWaiter" value="creationModeWaiter"/>
<c:set var="rowOrganizationSection" value="rowOrganizationSection"/>
<c:set var="rowProjectSection" value="rowProjectSection"/>
<c:set var="rowConnectionSection" value="rowConnectionSection"/>
<c:set var="fieldProjectKey" value="spaceProjectKey"/>
<c:set var="descriptionProjectConnection" value="Automatic: Project Connection"/>
<c:set var="optionProjectConnection" value="projectConnection"/>
<c:set var="descriptionOrganizationConnection" value="Automatic: Organization Connection"/>
<c:set var="optionOrganizationConnection" value="organizationConnection"/>
<c:set var="descriptionManual" value="Manual"/>
<c:set var="optionManual" value="manual"/>

<c:url value="/oauth/space/projects.html" var="projectesPage"/>

<jsp:include page="spaceApplicationCreator.jsp"/>
<jsp:include page="spaceConnectionsService.jsp"/>

<style type="text/css">
  tr.spaceNote table {
    width: 100%;
    border-spacing: 0;
  }

  tr.spaceNote table td {
    padding: 1px 0 1px 0;
    border: none;
  }

  tr.spaceNote td:first-child {
    border-top: none;
    padding-top: 0;
  }

  table.applicationUrls {
    padding: 4px;
  }

  .hidden {
   display: none !important;
  }

  .disable-click {
    pointer-events: none;
  }

  .spaceProjectControl {
    padding-left: 0.25em;
  }

  .tc-icon_space {
    cursor: pointer;
  }

  .linkish {
    cursor: pointer;
  }

  div#spaceProjects.spaceProjectsPopup {
    position: fixed !important;
  }
</style>

<%@include file="_spaceProjectApplicationCreator.jspf"%>
<%@include file="/oauth/_injectableCreateButtonSupport.jspf"%>

<script type="text/javascript">
  BS.SpaceParameters = {

    createdAppInfo: {},
    displayNameEdited: false,
    waitForPermissions: false,

    initCreationMode: function () {
      $('${idCreationModeWaiter}').show();
      this.fetchParentConnections(function (connections) {
        const sel = $('${idCreationModeSelect}');
        const projectOption = new Option('${descriptionProjectConnection}', '${optionProjectConnection}');
        const organizationOption = new Option('${descriptionOrganizationConnection}', '${optionOrganizationConnection}');
        const manualOption = new Option('${descriptionManual}', '${optionManual}');
        sel.append(projectOption);
        sel.append(organizationOption);
        sel.append(manualOption);

        if (connections.matchingConnections.length > 0) {
          sel.value = '${optionProjectConnection}';
        } else {
          projectOption.disabled = true;
          sel.value = '${optionOrganizationConnection}';
        }

        sel.enable();
        $('${idCreationModeWaiter}').hide();

        this.onSectionChange();
      });
      this.hideCreateOrganization();
      this.hideCreateProject();
      BS.InjectableCreateButtonSupport.hideCreateButtons();
      this.hideConnectionInputs();
    },

    onSectionChange: function () {
      const preset = this.getSelectedMode();
      switch(preset) {
        case '${optionManual}':
          $('${idManualHint}').show();
          $('${idOrganizationHint}').hide();
          $('${idProjectHint}').hide();
          this.hideCreateOrganization();
          this.hideCreateProject();
          this.showConnectionInputs();
          BS.InjectableCreateButtonSupport.hideCreateButtons();
          BS.InjectableCreateButtonSupport.restoreSaveButton();
          break;
        case '${optionOrganizationConnection}':
          $('${idManualHint}').hide();
          $('${idOrganizationHint}').show();
          $('${idProjectHint}').hide();
          this.showCreateOrganization();
          this.hideCreateProject();
          this.hideConnectionInputs();
          BS.InjectableCreateButtonSupport.hideCreateButtons();
          BS.InjectableCreateButtonSupport.injectCreateButton('createApplication');
          break;
        case '${optionProjectConnection}':
          $('${idManualHint}').hide();
          $('${idOrganizationHint}').hide();
          $('${idProjectHint}').show();
          this.hideCreateOrganization();
          this.showCreateProject();
          this.hideConnectionInputs();
          BS.InjectableCreateButtonSupport.hideCreateButtons();
          BS.InjectableCreateButtonSupport.injectCreateButton('createProjectApplication');
          break;
      }
      BS.OAuthConnectionDialog.recenterDialog();
    },

    fetchParentConnections: function (callback) {
      const that = this;
      BS.SpaceConnectionsService.listConnectionsWithCapabilities({
        projectId: '${project.projectId}',
        capabilities: ['CREATE_SUB_CONNECTION'],
        fullMatch: true,
        onSuccess: function (connections) {
          const sel = $j('#parentConnection');
          sel.empty();
          connections.matchingConnections.forEach((connection) => {
            sel.append(new Option(connection.displayName, connection.connectionId));
          });

          callback.call(that, connections);
        }
      });
    },

    fillProjectKey: function (project) {
      $('${fieldProjectKey}').value = project.key;
      this.updateDisplayName('Project ' + project.key);
    },

    updateDisplayName: function (newName) {
      if (!this.displayNameEdited) {
        $('${displayNameParam}').value = newName;
      }
    },

    showCreateProjectApplicationError: function (message) {
      const span = $j('#error_createProjectApplication');
      span.html(message);
      span.removeClass('hidden');
    },

    hideCreateProjectApplicationError: function() {
      $j('#error_createProjectApplication').addClass('hidden');
    },

    hideCreateProject: function () {
      $j('.${rowProjectSection}').hide();
    },

    showCreateProject: function () {
      $j('.${rowProjectSection}').show();
    },

    hideCreateOrganization: function () {
      $j('.${rowOrganizationSection}').hide();
    },

    showCreateOrganization: function () {
      $j('.${rowOrganizationSection}').show();
    },

    hideConnectionInputs: function () {
      $j('.${rowConnectionSection}').hide();
    },

    showConnectionInputs: function () {
      $j('.${rowConnectionSection}').show();
    },

    getSelectedParentConnection: function () {
      const sel = $('parentConnection');
      return sel.selectedIndex >= 0 ? sel.options[sel.selectedIndex] : null;
    },

    getSelectedMode: function () {
      <c:choose>
        <c:when test="${spaceFeatures.projectLevelConnectionEnabled()}">
          const sel = $('${idCreationModeSelect}');
          return sel.options[sel.selectedIndex].value;
        </c:when>
        <c:otherwise>
          return 'manual';
        </c:otherwise>
      </c:choose>
    },

    getDisplayName: function () {
      return $('${displayNameParam}').value;
    },

    onProjectKeyChange: function (field) {
      this.onFieldChange(field, 'error_${fieldProjectKey}', this.isProjectKeyValid);
      this.updateDisplayName('Project ' + field.value)
    },

    onParentConnectionChange: function (field) {
      this.onFieldChange(field, 'error_parentConnection', this.isParentConnectionValid);
    },

    onDisplayNameChange: function () {
      this.displayNameEdited = true;
      this.onFieldChange($('${displayNameParam}'), 'error_${displayNameParam}', this.isDisplayNameValid, 'Display name must not be empty');
    },

    onFieldChange: function (field, messageId, validator, errorMessage) {
      const msgSpan = $j("#" + messageId);
      if (!validator.call(this, field)) {
        field.classList.add("errorField");
        msgSpan.removeClass("hidden");
        if (errorMessage) {
          msgSpan.text(errorMessage);
        }
      } else {
        field.classList.remove("errorField");
        msgSpan.addClass("hidden");
      }
    },

    isProjectKeyValid: function (field) {
      return this.isNonEmpty(field.value);
    },

    isParentConnectionValid: function () {
      const option = this.getSelectedParentConnection();
      return option && this.isNonEmpty(option.value);
    },

    isDisplayNameValid: function () {
      return this.isNonEmpty(this.getDisplayName());
    },

    isNonEmpty: function (value) {
      return value != null && value.length > 0;
    },

    finishConnectionSetup: function () {
      BS.InjectableCreateButtonSupport.cleanupForm();
      $('connectionsTable').refresh();
      BS.OAuthConnectionDialog.close();
    }
  };

  BS.SpaceAutoCreator = OO.extend(BS.SpaceApplicationCreator, {
    create: function (createSpaceApplicationId) {
      if (!BS.SpaceParameters.isDisplayNameValid()) {
        return;
      }

      const displayName = BS.SpaceParameters.getDisplayName();
      const options = displayName ? {'connectionDisplayName': displayName} : null;

      this.createApplication(createSpaceApplicationId,
        '${SpaceConstants.DEFAULT_TC_INSTANCE_NAME}',
        '${project.externalId}',
        this.onComplete,
        options);
    },

    startWaiting: function () {
      $j('#error_createApplication').hide();
      $j('#createApplicationWaiter').show();
      $j('#createApplication').attr('disabled', 'disabled').addClass('disable-click');
    },

    stopWaiting: function () {
      $j('#createApplicationWaiter').hide();
    },

    onComplete: function () {
      BS.SpaceParameters.finishConnectionSetup();
    },

    onTimeout: function () {
      $j('#error_createApplication').text('Space Application creation did not succeed, please try again');
      $j('#error_createApplication').show();
      $j('#createApplication').removeAttr('disabled').removeClass('disable-click');
    },

    onFailure: function (message, canTryAgain) {
      $j('#createApplicationWaiter').hide();
      $j('#error_createApplication').text(message);
      $j('#error_createApplication').show();
      if (canTryAgain) {
        $j('#createApplication').removeAttr('disabled').removeClass('disable-click');
      }
    }
  });

  BS.SpaceParametersProjectApplicationCreator = OO.extend(BS.SpaceProjectApplicationCreator, {
    create: function() {
      BS.SpaceParameters.hideCreateProjectApplicationError();

      if (!BS.SpaceParameters.isDisplayNameValid()) {
        return;
      }

      const projectKeyField = $('${fieldProjectKey}');
      BS.SpaceParameters.onProjectKeyChange(projectKeyField);
      if (!BS.SpaceParameters.isProjectKeyValid(projectKeyField)) {
        console.log("creation aborted, invalid project key");
        return;
      }
      const projectKey = projectKeyField.value;

      BS.SpaceParameters.onParentConnectionChange($('parentConnection'));
      if (!BS.SpaceParameters.isParentConnectionValid()) {
        console.log("creation aborted, invalid parent connection id");
        return;
      }
      const parentConnectionId = BS.SpaceParameters.getSelectedParentConnection().value;

      const displayName = BS.SpaceParameters.getDisplayName();

      this.doCreate(projectKey, '${project.externalId}', parentConnectionId, displayName, false,
        function (info) {
          BS.SpaceParameters.createdAppInfo = info;
          BS.SpaceParameters.finishConnectionSetup();
        },
        function (message) {
          BS.SpaceParameters.showCreateProjectApplicationError(message);
        });
    },

    startWaiting: function () {
      $j('#createProjectApplicationWaiter').show();
      $j('#createProjectApplication').prop('disabled', true).addClass('disable-click');
    },

    stopWaiting: function () {
      $j('#createProjectApplicationWaiter').hide();
      $j('#createProjectApplication').prop('disabled', false).removeClass('disable-click');
    }
  });

  BS.SpaceProjectsPopup = new BS.Popup('spaceProjects', {
    url: '${projectesPage}',
    method: 'get',
    hideDelay: 0,
    hideOnMouseOut: false,
    hideOnMouseClickOutside: true,
    className: 'spaceProjectsPopup'
  });
  BS.SpaceProjectsPopup.showPopup = function (nearestElement) {
    BS.SpaceParameters.onParentConnectionChange($('parentConnection'));
    if (!BS.SpaceParameters.isParentConnectionValid()) {
      console.log("popup aborted, invalid parent connection id");
      return;
    }
    const parentConnectionId = BS.SpaceParameters.getSelectedParentConnection().value;

    this.options.parameters = {
      'projectId': '${project.externalId}',
      'connectionId': parentConnectionId,
      'showMode': 'popup',
      'onlyUnconnected': true,
      'selectMode': '${SpaceConstants.SELECT_MODE_USE}'
    };
    const that = this;

    window.SpaceProjectsContentUpdater = function () {
      that.hidePopup(0);
      that.showPopupNearElement(nearestElement);
    };

    window.projectCallback = function (project) {
      BS.SpaceParameters.fillProjectKey(project);
      BS.SpaceProjectsPopup.hidePopup();
    };

    this.showPopupNearElement(nearestElement);
  };

  $j(document).ready(function () {
    if (${newConnection}) {
      if (${spaceFeatures.projectLevelConnectionEnabled()}) {
        BS.SpaceParameters.initCreationMode();
      } else {
       $('${idManualHint}').show();
      }
    }
  });
</script>

<oauth:displayName onchange="BS.SpaceParameters.onDisplayNameChange();" />

<c:choose>
  <c:when test="${newConnection}">
    <c:set var="createSpaceApplicationId" value="<%=UUID.randomUUID().toString()%>"/>

    <c:if test="${spaceFeatures.projectLevelConnectionEnabled()}">

      <oauth:creationMode
          id="${idCreationModeSelect}"
          idWaiter="${idCreationModeWaiter}"
          onchange="BS.SpaceParameters.onSectionChange();"
          disabled="true"
          note="Choose between manual configuration of the connection or automatic setup of the Space application by TeamCity."
      />

      <%@include file="_manualHint.jspf"%>
      <%@include file="_organizationHint.jspf"%>
      <%@include file="_projectHint.jspf"%>

      <tr class="${rowOrganizationSection}">
        <td colspan="2" style="border-top: none">
          <forms:button id="createApplication"
                        onclick="BS.SpaceAutoCreator.create('${createSpaceApplicationId}');"
                        className="btn_primary submitButton createButton">
            Create Space Application
          </forms:button>
          <forms:saving id="createApplicationWaiter" style="float: none;"/>
          <span class="error" style="display: none;" id="error_createApplication">Space Application creation did not succeed, please try again</span>
        </td>
      </tr>

      <tr class="${rowProjectSection}">
        <th><label for="parentConnection">Organization connection:<l:star/></label></th>
        <td>
          <forms:select name="parentConnection" onchange="BS.SpaceParameters.onParentConnectionChange(this);" style="width: 20em;"/>
          <span class="error hidden" id="error_parentConnection">An organization connection must be selected</span>
        </td>
      </tr>

      <tr class="${rowProjectSection}">
        <th><label for="${fieldProjectKey}">Space project key:<l:star/></label></th>
        <td>
          <div class="posRel">
            <forms:textField name="${fieldProjectKey}"
                             onchange="BS.SpaceParameters.onProjectKeyChange(this);"
                             disabled="true"/>
            <span class="spaceProjectControl">
              <i class="tc-icon icon16 tc-icon_space"
                 title="Pick a project"
                 onclick="BS.SpaceProjectsPopup.showPopup(this)"></i>
            </span>
          </div>
          <span class="error hidden" id="error_${fieldProjectKey}">Project key must be specified</span>
        </td>
      </tr>

      <tr class="${rowProjectSection}">
        <td colspan="2" style="border-top: none">
          <forms:button id="createProjectApplication"
                        onclick="BS.SpaceParametersProjectApplicationCreator.create();"
                        className="btn_primary submitButton createButton">
            Create Space Application
          </forms:button>
          <forms:saving id="createProjectApplicationWaiter" style="float: none;"/>
          <span class="error hidden" id="error_createProjectApplication">[error message]</span>
        </td>
      </tr>

    </c:if>
  </c:when>
</c:choose>

<tr class="${rowConnectionSection}">
  <th><label for="${keys.spaceServerUrl}">Space URL:<l:star/></label></th>
  <td>
    <props:textProperty name="${keys.spaceServerUrl}" className="longField"/>
    <span class="error" id="error_${keys.spaceServerUrl}"></span>
  </td>
</tr>

<tr class="${rowConnectionSection}">
  <th><label for="${keys.spaceClientId}">Client ID:<l:star/></label></th>
  <td>
    <props:textProperty name="${keys.spaceClientId}" className="longField"/>
    <span class="error" id="error_${keys.spaceClientId}"></span>
  </td>
</tr>

<tr class="${rowConnectionSection}">
  <th><label for="${keys.spaceClientSecret}">Client secret:<l:star/></label></th>
  <td>
    <props:passwordProperty name="${keys.spaceClientSecret}" className="longField"/>
    <span class="error" id="error_${keys.spaceClientSecret}"></span>
  </td>
</tr>

<oauth:uniqueRedirectCheckbox
    project="${project}"
    connectionBean="${oauthConnectionBean}"
    oauthProvider="${oauthProvider}"
    urlElement="firstSpaceRootUrl"
    initialUrl="${redirectUrl}"
    uniqueUrl="${redirectUrlUnique}"
    fallbackUrl="${redirectUrlFallback}"
    providerDisplayName="Space"
    isNewConnection="${isNewConnection}"
    rowClassName="${rowConnectionSection}"
/>