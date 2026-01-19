<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceOAuthProvider" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceOAuthKeys" %>
<%@ page import="jetbrains.buildServer.util.StringUtil" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceConstants" %>
<%@ include file="/include-internal.jsp" %>
<%@ include file="_spaceConstants.jspf"%>
<%@ include file="_preSelectionSupport.jspf"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="afn" uri="/WEB-INF/functions/authz" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop" %>
<jsp:include page="spaceConnectionsService.jsp"/>
<jsp:useBean id="spaceConnections" scope="request" type="java.util.Map"/>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<jsp:useBean id="showMode" scope="request" type="java.lang.String"/>
<jsp:useBean id="spaceFeatures" scope="request" type="jetbrains.buildServer.serverSide.oauth.space.SpaceFeatures"/>
<style type="text/css">
  .spaceRepoControl {
    padding-left: 0.25em;
  }

  .tc-icon_space {
    cursor: pointer;
  }

  a > .tc-icon_space_disabled {
    text-decoration: none;
  }
</style>
<c:set var="createPrefix" value="${showMode == 'createProjectMenu' ? 'Create project' : 'Create build configuration'}"/>
<c:set var="spaceServerUrl" value="<%= SpaceOAuthKeys.SPACE_SERVER_URL %>"/>
<c:url value="/oauth/space/repositories.html" var="repositoriesPage"/>
<c:url value="/oauth/space/projects.html" var="projectsPage"/>
<c:set var="cameFromUrl" value="${empty param['cameFromUrl'] ? pageUrl : param['cameFromUrl']}"/>
<c:set var="repositoriesPage" value="${repositoriesPage}?cameFromUrl=${util:urlEscape(cameFromUrl)}"/>
<c:set var="projectsPage" value="${projectsPage}?cameFromUrl=${util:urlEscape(cameFromUrl)}"/>
<c:url value="/oauth/space/onDemand.html?projectId=${project.externalId}&showMode=${util:urlEscape(showMode)}" var="onDemandPage"/>
<c:set var="vcsType" value="${vcsType == null ? '' : vcsType}"/>
<c:set var="connectionType" value="<%=SpaceOAuthProvider.TYPE%>"/>
<c:url var="oauthConnectionsUrl" value="/admin/editProject.html?projectId=${project.externalId}&tab=oauthConnections"/>
<c:set var="idConnectionIconsWaiter" value="connectionButtonsWaiter"/>
<c:set var="idConnectionButtonsWaiter" value="connectionLoadWaiter"/>
<script type="text/javascript">
  BS.SpaceRepositoriesPopup = new BS.Popup('spaceRepositories', {
    method: "get",
    hideDelay: 0,
    hideOnMouseOut: false,
    hideOnMouseClickOutside: true,
    forceReload: true
  });

  BS.SpaceRepositoriesPopup.showPopup = function (nearestElement, connectionId, vcsType, isInstance) {
    this.options.url = isInstance ? '${projectsPage}' : '${repositoriesPage}';
    this.options.parameters = "projectId=${project.externalId}&connectionId=" + connectionId + "&vcsType=" + vcsType + "&showMode=popup&selectMode=${SpaceConstants.SELECT_MODE_CONNECT}";
    this.nearestElement = nearestElement;

    var that = this;
    const updater = function () {
      that.hidePopup(0);
      that.showPopupNearElement(nearestElement);
    };
    window.SpaceRepositoriesContentUpdater = updater;
    window.SpaceProjectsContentUpdater = updater;

    this.showPopupNearElement(nearestElement);
  };

  BS.SpaceConnectionControlLoader = {
    connectionCount: 0,

    loadConnections: function (showMode) {
      this.connectionCount = 0;
      $j('#${idConnectionButtonsWaiter}').show();
      $j('#${idConnectionIconsWaiter}').show();

      const that = this;
      this.load({
        capabilities: ['CREATE_SUB_CONNECTION', 'ISSUE_USER_TOKEN'],
        fullMatch: false,
        unwantedCapabilities: ['IS_SUB_CONNECTION'],
        onComplete: function () {
          that.loadingDone();
        },
        onSuccess: function (connections) {
          if (connections && connections.matchingConnections) {
            connections.matchingConnections.forEach(connection => {
              const isOrganizationConnection = (${spaceFeatures.projectLevelConnectionEnabled()} &&
                (connection.testedCapabilities.includes('CREATE_SUB_CONNECTION') || connection.pendingConnectionType === 'PENDING_ORGANIZATION_CONNECTION'));
              that.createConnectionControl(showMode, connection, isOrganizationConnection);
              that.connectionCount++;
            });
          }
        }
      });
    },

    load: function (params) {
      const that = this;
      BS.SpaceConnectionsService.listConnectionsWithCapabilities({
        projectId: '${project.projectId}',
        capabilities: params.capabilities,
        unwantedCapabilities: params.unwantedCapabilities,
        fullMatch: params.fullMatch,
        queryUserTokens: true,
        queryPendingType: true,
        onSuccess: function (connections) {
          params.onSuccess(connections);
          params.onComplete();
        },
        onFailure: function (response) {
          $j('#${idConnectionButtonsWaiter}').hide();
          $j('#${idConnectionIconsWaiter}').hide();
          const responseText = response.responseText;
          const error = (responseText && responseText.length > 0) ? responseText : 'Empty response while loading Space connection';
          that.showError(error);
          params.onComplete();
        },
        onTimeout: function () {
          $j('#${idConnectionButtonsWaiter}').hide();
          $j('#${idConnectionIconsWaiter}').hide();
          that.showError('Timeout while loading Space connection');
          params.onComplete();
        }
      });
    },

    createConnectionControl: function (showMode, connection, isOrganizationConnection) {
      if (showMode === 'popup') {
        this.createConnectionIcon(connection, isOrganizationConnection);
      } else {
        this.createConnectionButton(showMode, connection, isOrganizationConnection);
      }
    },

    createConnectionIcon: function (connection, isOrganizationConnection) {
      const waiter = $j('#${idConnectionIconsWaiter}');

      const title = `Pick repository from \${connection.displayName} (\${connection.serverUrl})`;

      const span = document.createElement("span");
      span.classList.add('spaceRepoControl');

      const icon = document.createElement("i");
      icon.classList.add('tc-icon', 'icon16', 'tc-icon_space');
      icon.title = title;
      icon.onclick = function () {
        BS.SpaceRepositoriesPopup.showPopup(icon, connection.connectionId, '${vcsType}', isOrganizationConnection);
      };

      span.append(icon);
      waiter.before(span);
    },

    createAddConnectionIcon: function() {
      const waiter = $j('#${idConnectionIconsWaiter}');

      const span = document.createElement("span");
      span.classList.add('spaceRepoControl');

      const anchor = document.createElement("a");
      anchor.href = '${oauthConnectionsUrl}#addDialog=<%=StringUtil.encodeURLParameter(SpaceOAuthProvider.TYPE)%>';

      const icon = document.createElement("i");
      icon.classList.add('tc-icon', 'icon16', 'tc-icon_space_disabled');
      icon.title = 'Click to set up connection to Space';

      span.append(anchor);
      anchor.append(icon);
      waiter.before(span);
    },

    createConnectionButton: function (showMode, connection, isOrganizationConnection) {
      const waiter = $j('#${idConnectionButtonsWaiter}');

      let url = isOrganizationConnection ? '${projectsPage}' : '${repositoriesPage}';
      url += '&projectId=${project.externalId}'
        + '&connectionId=' + encodeURIComponent(connection.connectionId)
        + '&showMode=' + encodeURIComponent(showMode)
        + '&onlyUnconnected=false';
      if (isOrganizationConnection) {
        url += '&selectMode=' + encodeURIComponent('${SpaceConstants.SELECT_MODE_CONNECT}');
      }

      const anchor = document.createElement("a");
      anchor.id = 'control_' + connection.connectionId;
      anchor.href = '#space';
      anchor.classList.add('createOption', 'readyToUseOption');
      if (connection.userTokensExist) {
        anchor.classList.add('preferableOption');
      }
      anchor.dataset.url = url;

      const heading = document.createElement("h3");
      const icon = document.createElement("i");
      icon.classList.add('tc-icon', 'icon16', 'tc-icon_space');
      heading.append(icon);
      heading.append(`From \${connection.displayName}`);

      const secondLine = document.createElement("div");
      secondLine.classList.add('createOption__second-line');
      secondLine.append(connection.serverUrl);

      anchor.append(heading);
      anchor.append(secondLine);
      waiter.before(anchor);
    },

    createOnDemandButton: function () {
      const waiter = $j('#${idConnectionButtonsWaiter}');

      const nameAnchor = document.createElement("a");
      nameAnchor.name = 'spaceOnDemand';

      const anchor = document.createElement("a");
      anchor.id = 'control_ondemand';
      anchor.href = '#spaceOnDemand';
      anchor.classList.add('createOption', 'readyToUseOption');
      anchor.dataset.url = '${onDemandPage}';

      const heading = document.createElement("h3");
      const icon = document.createElement("i");
      icon.classList.add('tc-icon', 'icon16', 'tc-icon_space');
      heading.append(icon);
      heading.append('From JetBrains Space');

      anchor.append(heading);

      if (BS.SpacePreSelection.isOrganizationPreSelected()) {
        const secondLine = document.createElement("div");
        secondLine.classList.add('createOption__second-line');
        secondLine.append(BS.SpacePreSelection.preSelectedOrganizationUrl);
        anchor.append(secondLine);
      }

      waiter.before(anchor);
    },

    loadingDone: function () {
      $j('#${idConnectionButtonsWaiter}').hide();
      $j('#${idConnectionIconsWaiter}').hide();

      if (${afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}) {
        if (${showMode == 'popup'} && this.connectionCount === 0) {
          this.createAddConnectionIcon();
        } else if ((${spaceFeatures.onDemandEnabled()} && this.connectionCount === 0) || BS.SpacePreSelection.buildSuggestion === '${buildSuggestionOnDemand}') {
          this.createOnDemandButton();
        }
      }

      <c:if test="${spaceFeatures.capabilitiesEnabled() and showMode != 'popup'}">
        BS.CreateObjectMenu.extensionIsReady('space');
      </c:if>
    },

    showError: function (error) {
      TeamCityAPI.Services.AlertService.addAlert(error, "error");
    }
  };
</script>

<c:if test="${spaceFeatures.capabilitiesEnabled() and showMode != 'popup'}">
  <script type="text/javascript">
    BS.CreateObjectMenu.waitForExtension('space');
  </script>
</c:if>

<c:choose>
  <c:when test="${showMode == 'popup'}">

    <c:if test="${spaceFeatures.capabilitiesEnabled()}">
      <forms:progressRing id="${idConnectionIconsWaiter}" progressTitle="Loading Space connection..." className="tc-icon"/>
      <script type="text/javascript">
        BS.SpaceConnectionControlLoader.loadConnections('<bs:forJs>${showMode}</bs:forJs>');
      </script>
    </c:if>

    <c:forEach items="${spaceConnections}" var="entry">
      <c:set value="${entry.key}" var="connection"/>
      <c:set var="title">Pick repository from <c:out value="${connection.connectionDisplayName.concat(' (').concat(connection.parameters[spaceServerUrl]).concat(')')}"/></c:set>
      <span class="spaceRepoControl" id="control_${connection.id}">
        <i class="tc-icon icon16 tc-icon_space" title="${title}" onclick="BS.SpaceRepositoriesPopup.showPopup(this, '${connection.id}', '${vcsType}', false)"></i>
      </span>
    </c:forEach>
    <c:if test="${fn:length(spaceConnections) == 0 and afn:permissionGrantedForProject(project, 'EDIT_PROJECT') and not spaceFeatures.capabilitiesEnabled()}">
      <span class="spaceRepoControl">
        <a href="${oauthConnectionsUrl}#addDialog=<%=StringUtil.encodeURLParameter(SpaceOAuthProvider.TYPE)%>">
          <i class="tc-icon icon16 tc-icon_space_disabled" title="Click to set up connection to Space"></i>
        </a>
      </span>
    </c:if>
  </c:when>
  <c:otherwise>

    <c:if test="${spaceFeatures.capabilitiesEnabled()}">
      <div id=${idConnectionButtonsWaiter} class="createOption">
        <forms:progressRing progressTitle="Loading Space connection..."/>
        Loading Space connection...
      </div>
      <script type="text/javascript">
        BS.SpaceConnectionControlLoader.loadConnections('<bs:forJs>${showMode}</bs:forJs>');
      </script>
    </c:if>

    <c:forEach items="${spaceConnections}" var="entry">
      <c:set value="${entry.key}" var="connection"/>
      <a href="#space"
         id="control_${connection.id}"
         class="createOption readyToUseOption <c:if test="${entry.value}">preferableOption</c:if>"
         data-url="${repositoriesPage}&projectId=${project.externalId}&connectionId=${connection.id}&showMode=${util:urlEscape(showMode)}">
        <h3><i class="tc-icon icon16 tc-icon_space"></i> From <c:out value="${connection.connectionDisplayName}"/></h3>
        <div class="createOption__second-line"><c:out value="${connection.parameters[spaceServerUrl]}"/></div>
      </a>
    </c:forEach>

    <c:if test="${fn:length(spaceConnections) == 0 and afn:permissionGrantedForProject(project, 'EDIT_PROJECT') and spaceFeatures.onDemandEnabled() and not spaceFeatures.capabilitiesEnabled()}">
      <a name="spaceOnDemand"></a>
      <a href="#spaceOnDemand" class="createOption readyToUseOption" data-url="${onDemandPage}">
        <h3><i class="tc-icon icon16 tc-icon_space"></i> From JetBrains Space</h3>
      </a>
    </c:if>

  </c:otherwise>
</c:choose>