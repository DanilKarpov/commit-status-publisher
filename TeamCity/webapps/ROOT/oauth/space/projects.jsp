<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceConstants" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceApplicationController" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ include file="/include-internal.jsp" %>
<%@ include file="_spaceConstants.jspf" %>
<%@ include file="_preSelectionSupport.jspf" %>
<%--@elvariable id="errorCode" type="java.lang.String"--%>
<%--@elvariable id="vcsType" type="java.lang.String"--%>
<%--@elvariable id="errorMessage" type="java.lang.String"--%>
<%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
<%--@elvariable id="projects" type="java.util.List<jetbrains.buildServer.serverSide.oauth.space.pojo.SpaceProject>"--%>
<%--@elvariable id="projectsCount" type="java.lang.Integer"--%>
<%--@elvariable id="projectConnections" type="java.util.Map<java.lang.String, jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor>"--%>
<%--@elvariable id="unconnectedCount" type="java.lang.Integer"--%>
<%--@elvariable id="onlyUnconnected" type="java.lang.Boolean"--%>
<%--@elvariable id="selectMode" type="java.lang.String"--%>
<%--@elvariable id="isPendingConnection" type="java.lang.Boolean"--%>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor" scope="request"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="showMode" type="java.lang.String" scope="request"/>

<c:url value="/oauth/space/repositories.html" var="repositoriesPage"/>
<c:set var="cameFromUrl" value="${empty param['cameFromUrl'] ? pageUrl : param['cameFromUrl']}"/>
<c:set var="repositoriesPage" value="${repositoriesPage}?cameFromUrl=${util:urlEscape(cameFromUrl)}"/>
<c:set var="currentSpaceApplicationUrl" value="${SpaceApplicationController.PATH}"/>
<c:set var="classIconConnected" value="tc-icon_space"/>
<c:set var="classIconUnconnected" value="tc-icon_space_disabled"/>
<c:set var="isPopup" value="${showMode eq 'popup'}"/>
<c:set var="isCreateProject" value="${showMode == 'createProjectMenu'}"/>

<jsp:include page="spaceConnectionsService.jsp"/>

<c:set var="styles">
  <bs:linkCSS>
    /css/forms.css
  </bs:linkCSS>
  <style type="text/css">
    #spaceRepositories {
      padding: 8px;
    }

    div.filter, div.reposCount {
      padding: 4px 4px 0px 4px;
    }

    div.inplaceFilterDiv {
      border: none;
    }

    ul.menuList {
      padding: 0px 4px 0 0;
      margin-left: 0;
    }

    ul.menuList li {
      list-style: none;
      padding: 4px;
      border-bottom: none;
    }

    ul.menuList li:hover, ul.menuList li:hover a {
      text-decoration: none;
    }

    ul.menuList li a {
      display: inline;
    }

    ul.menuList li.repository {
      padding-left: 10px;
    }

    ul.menuList li.repository.selected {
      background-color: var(--ring-hover-background-color, #ebf6ff);
    }

    ul.menuList li.groupName {
      font-size: 110%;
      color: gray;
      border-bottom: 1px solid var(--ring-line-color, #dfe5eb);
    }

    ul.menuList li.groupName:hover {
      background-color: var(--ring-content-background-color, #fff);
      color: gray;
      text-decoration: none;
      cursor: auto;
    }

    div.authenticated {
      margin: 25%;
      font-size: 120%;
    }

    ul.menuList span.useRepoProgress {
      display: none;
      float: none;
      margin-left: 0.5em;
    }

    .useRepoProgress i {
      float: none;
    }

    .cancelButton {
      margin-top: 2em;
    }

    div.projectConnectionInfo {
      margin-left: 16px;
    }

    .projectConnectionInfo span {
      white-space: pre;
    }
  </style>
</c:set>

<c:choose>
  <c:when test="${errorCode == 'newTokenRequired'}">
    ${styles}
    <div>
      To show available projects TeamCity requires access to your Space account.
      <br/>
      <br/>
      <iframe hidden id="iframe_${oauthProvider.id}">
        <script>
          window.SpaceProjectsContentUpdater = parent.SpaceProjectsContentUpdater;
        </script>
      </iframe>
      <c:set var="onclick">
        var iframe = document.getElementById('iframe_${oauthProvider.id}');
        var win = BS.Util.popupWindow(
          window['base_uri'] + '/oauth/space/projects.html?projectId=${project.externalId}' +
          '&connectionId=${oauthProvider.id}' +
          '&vcsType=${vcsType}' +
          '&updateToken=true' +
          '&showMode=popup',
          'repositories_${oauthProvider.id}',
          {safe: false, opener: iframe.contentWindow},
        );
        var interval = window.setInterval(function() {
          try {
            if (win == null || win.closed) {
              window.clearInterval(interval);
              window.SpaceProjectsContentUpdater();
            }
            } catch (e) { }
        }, 1000);
      </c:set>
      <form id="signInButtons">
        <forms:button onclick="${onclick}" className="btn_primary submitButton">Sign in to Space</forms:button>
        <forms:button onclick="window.SpaceProjectsContentUpdater()">Refresh</forms:button>
        <forms:progressRing style="display:none; float: none; margin-left: 0.5em;" id="refreshProgress"/>
      </form>
    </div>
    <c:if test="${showMode ne 'popup'}">
      <script type="text/javascript">
        window.SpaceProjectsContentUpdater = function () {
          $j('#refreshProgress').show();
          $j('#signInButtons a').attr('disabled', true);
          if (refreshCurrentContainer) refreshCurrentContainer();
        }
      </script>
  </c:if>
  </c:when>

  <c:when test="${errorCode == 'requestFailed'}">
    ${styles}
    <div class="errorMessage"><c:out value="${errorMessage}"/></div>
  </c:when>

  <c:when test="${errorCode == 'tokenObtained'}">
    <bs:externalPage>
      <jsp:attribute name="page_title">Space Cloud Authentication</jsp:attribute>
      <jsp:attribute name="head_include">
        ${styles}
        <script type="text/javascript">
          if (window.opener && window.opener.parent.SpaceProjectsContentUpdater) {
            window.opener.parent.SpaceProjectsContentUpdater();
          }
          window.close();
        </script>
      </jsp:attribute>
      <jsp:attribute name="body_include">
        <div class="authenticated">
          Authentication successful! Please close this window and click "Refresh" button.
        </div>
      </jsp:attribute>
    </bs:externalPage>
  </c:when>

  <c:otherwise>
    ${styles}
    <%@include file="_spaceProjectConnectionDialog.jspf"%>
    <script type="text/javascript">
      BS.SpaceProjects = {
        projects: new Map(),
        connectedProjects: new Map(),

        onProjectSelected: function (projectId) {
          if ($j('#progress_' + projectId).is(":visible")) return; // double submit

          this.showProgress(projectId);

          const project = this.projects.get(projectId);
          if (!project) {
            console.log("project with id " + projectId + " not found");
            return;
          }

          const selectMode = '<c:out value="${selectMode}"/>';
          if (selectMode === '${SpaceConstants.SELECT_MODE_USE}') {
            this.useProject(project);
          } else if (selectMode === '${SpaceConstants.SELECT_MODE_CONNECT}') {
            if (project.isConnected) {
              this.showProjectRepositories(project);
            } else {
              this.connectProject(project);
            }
          } else {
            alert("unsupported select mode parameter " + selectMode);
          }
        },

        useProject: function (project) {
          if (!window.projectCallback) {
            alert("function window.projectCallback is not defined");
            return;
          }

          if (project) {
            window.projectCallback(project);
          }
        },

        connectProject: function (project) {
          const that = this;
          BS.SpaceAddProjectConnectionDialog.show({
            project: project,
            onComplete: function () {
              that.hideProgress(project.id);
            },
            onSuccess: function (info) {
              if (!info.sameProject) {
                that.navigateToOtherProject(info.targetProject);
                return;
              }

              const icon = $j(`#icon_\${project.id}`);
              icon.removeClass('${classIconUnconnected}');
              icon.addClass('${classIconConnected}');

              if (info.newProject) {
                that.attachTransientConnectionInfo(project.id);
              }

              project.isConnected = true;
              project.connectionId = info.connectionId;
              that.showProjectRepositories(project);
            },
            onFailure: function (message) {
              TeamCityAPI.Services.AlertService.addAlert(message, "error");
            }
          });
        },

        showProjectRepositories: function (project) {
          if (${isPopup}) {
            const element = BS.SpaceRepositoriesPopup.nearestElement;
            BS.SpaceRepositoriesPopup.hidePopup();
            BS.SpaceRepositoriesPopup.showPopup(element, project.connectionId, '${vcsType}', false);
            return;
          }

          const that = this;
          $j('#repositoriesPage').hide();
          $j('.repositoriesRow').show();
          $j('#loadRepositoriesMessage').show();
          $j('#loadRepositories').show();
          $j('ul.menuList li.repository').removeClass('selected');
          $j('#menuItem_' + project.id).addClass('selected');

          BS.ajaxUpdater($('repositoriesPage'), '${repositoriesPage}', {
            method: 'get',
            evalScripts: true,
            parameters: {
              projectId: '${project.externalId}',
              connectionId: project.connectionId,
              showMode: '${util:urlEscape(showMode)}',
              content: 'embed'
            },
            onComplete: function () {
              $j('#loadRepositoriesMessage').hide();
              $j('#loadRepositories').hide();
              $j('#repositoriesPage').show();
              that.hideProgress(project.id);
            }
          });
        },

        navigateToOtherProject: function (targetProject) {
          $j('#repositoriesPage').hide();
          $j('.repositoriesRow').show();
          $j('#loadRepositoriesMessage').show();
          $j('#loadRepositories').show();

          const url = new URL(window.location.href);
          url.searchParams.set('projectId', targetProject);
          window.location.href = url.toString();
        },

        preselect: function () {
          if (!BS.SpacePreSelection.isAnythingPreSelected()) {
            this.preselectSingleConnected();
            return;
          }

          for (const project of this.connectedProjects.values()) {
            if (BS.SpacePreSelection.isConnectionPreSelected(project.connectionId)) {
              this.showProjectRepositories(project);
              return;
            }
          }

          if (BS.SpacePreSelection.buildSuggestion === '${buildSuggestionCreateProjectConnection}') {
            for (const project of this.projects.values()) {
              if (project.key === BS.SpacePreSelection.preSelectedProjectKey) {
                if (this.connectedProjects.has(project.id)) {
                  this.showProjectRepositories(project);
                } else {
                  this.connectProject(project);
                }
                return;
              }
            }
          }
        },

        preselectSingleConnected: function() {
          if (!${isPopup} && this.connectedProjects.size == 1) {
            this.showProjectRepositories(this.connectedProjects.values().next().value);
          }
        },

        showProgress: function (projectId) {
          $j('#progress_' + projectId).show();
        },

        hideProgress: function (projectId) {
          $j('#progress_' + projectId).hide();
        },

        attachTransientConnectionInfo: function (projectId) {
          const menuItem = $j('#menuItem_' + projectId);
          menuItem.find('div.projectConnectionInfo').remove();

          const infoDiv = $j('<div></div>', {
            class: 'projectConnectionInfo smallNote'
          });
          infoDiv.append($j('<span> via connection in creation</span>'));
          menuItem.append(infoDiv);
        }
      };

      <c:forEach items="${projects}" var="project">
        BS.SpaceProjects.projects.set('${project.id}', {
          id: '${project.id}',
          name: '<c:out value="${project.name}"/>',
          key: '${project.key.key}'
        });
      </c:forEach>

      $j(document).ready(function () {
        BS.SpaceProjects.preselect();
      });
    </script>
    <div>
      <c:set var="contId"><bs:id/></c:set>
      <c:set var="significantCount" value="${onlyUnconnected ? unconnectedCount : projectsCount}"/>
      <c:if test="${significantCount > 10}">
        <div class="grayNote reposCount">Found <strong>${significantCount}</strong> <bs:plural txt="project" val="${significantCount}"/></div>
        <div class="filter">
          <bs:inplaceFilter containerId="${contId}" activate="true" filterText="&lt;filter projects>"/>
        </div>
      </c:if>
      <c:if test="${significantCount eq 0}">
        <c:choose>
          <c:when test="${isPendingConnection}">
            <%@include file="_pendingConnectionSupport.jspf"%>
          </c:when>
          <c:otherwise>
            <div>There were no ${onlyUnconnected ? 'unconnected' : ''} projects found.</div>
          </c:otherwise>
        </c:choose>
      </c:if>
      <c:if test="${significantCount gt 0}">
        <ul id="${contId}" class="menuList">
          <li class="groupName">
            Your ${onlyUnconnected ? 'unconnected' : ''} projects (${significantCount})
          </li>
          <c:forEach items="${projects}" var="project" varStatus="pos">
            <c:set var="projectConnection" value="${projectConnections[project.key.key]}"/>
            <c:set var="isConnected" value="${not empty projectConnection and (not projectConnection.hidden or isCreateProject)}"/>
            <c:set var="iconClass" value="${isConnected ? classIconConnected : classIconUnconnected}"/>

            <c:if test="${isConnected}">
              <script type="text/javascript">
                {
                  const project = BS.SpaceProjects.projects.get('${project.id}');
                  project.isConnected = true;
                  project.connectionId = '${projectConnection.id}';
                  BS.SpaceProjects.connectedProjects.set('${project.id}', project);
                }
              </script>
            </c:if>

            <c:if test="${not onlyUnconnected or not isConnected}">
              <li id="menuItem_${project.id}"
                  class="repository inplaceFiltered"
                  onclick="BS.SpaceProjects.onProjectSelected('${project.id}')"
                  title="Click to use this project" ${pos.last ? "style='margin-bottom: 1em;'" : ''}>
                <i id="icon_${project.id}" class="repoStatus tc-icon icon16 ${iconClass}"></i>
                <c:out value="${project.name}"/>
                <c:if test="${isConnected}">
                  <div class="projectConnectionInfo smallNote">
                    <span> via connection <c:out value="${projectConnection.displayName}"/></span>
                  </div>
                </c:if>
                <span id="progress_${project.id}" class="useRepoProgress"><forms:progressRing/> Verifying connection...</span>
              </li>
            </c:if>
          </c:forEach>
        </ul>
      </c:if>
    </div>
  </c:otherwise>
</c:choose>
