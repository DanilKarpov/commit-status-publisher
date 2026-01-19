<%@ page import="jetbrains.buildServer.serverSide.oauth.space.pojo.SpaceRepository" %>
<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp" %>
<%@ include file="_spaceConstants.jspf" %>
<%@ include file="_preSelectionSupport.jspf" %>
<%--@elvariable id="errorCode" type="java.lang.String"--%>
<%--@elvariable id="vcsType" type="java.lang.String"--%>
<%--@elvariable id="errorMessage" type="java.lang.String"--%>
<%--@elvariable id="oauthUsername" type="java.lang.String"--%>
<%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
<%--@elvariable id="repositories" type="java.util.List<jetbrains.buildServer.serverSide.oauth.space.pojo.SpaceRepositoryGroup>"--%>
<%--@elvariable id="repositoriesNum" type="java.lang.Integer"--%>
<%--@elvariable id="tokenType" type="java.lang.String"--%>
<%--@elvariable id="tokenId" type="java.lang.String"--%>
<%--@elvariable id="isPermanentToken" type="java.lang.Boolean"--%>
<%--@elvariable id="isNonPersonalToken" type="java.lang.Boolean"--%>
<%--@elvariable id="tokenId" type="java.lang.String"--%>
<%--@elvariable id="teamcityName" type="java.lang.String"--%>
<%--@elvariable id="teamcityUsername" type="java.lang.String"--%>
<%--@elvariable id="isPendingConnection" type="java.lang.Boolean"--%>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor" scope="request"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="showMode" type="java.lang.String" scope="request"/>
<jsp:include page="spaceConnectionsService.jsp"/>
<jsp:include page="spaceTokenService.jsp"/>
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

    .createBuildHint {
      margin-left: 0;
    }
  </style>
</c:set>
<script type="text/javascript">
  var acquiredNewToken = false;
</script>
<c:choose>
  <c:when test="${errorCode == 'newTokenRequired'}">
    ${styles}
    <div>
      To show available repositories TeamCity requires access to your Space account.
      <br/>
      <br/>
      <iframe hidden id="iframe_${oauthProvider.id}">
        <script>
          window.SpaceRepositoriesContentUpdater = parent.SpaceRepositoriesContentUpdater;
        </script>
      </iframe>
      <c:set var="onclick">
        acquiredNewToken = true;
        var iframe = document.getElementById('iframe_${oauthProvider.id}');
        var win = BS.Util.popupWindow(
          window['base_uri'] + '/oauth/space/repositories.html?projectId=${project.externalId}&connectionId=${oauthProvider.id}&vcsType=${vcsType}&updateToken=true&showMode=<%=WebUtil
          .encode(showMode)%>&userId=${currentUser.id}',
        'repositories_${oauthProvider.id}',
        {safe: false, opener: iframe.contentWindow},
        );
        var interval = window.setInterval(function() {
        try {
        if (win == null || win.closed) {
        window.clearInterval(interval);
        window.SpaceRepositoriesContentUpdater();
        }
        } catch (e) {
        }
        }, 1000);
      </c:set>
      <form id="signInButtons">
        <forms:button onclick="${onclick}" className="btn_primary submitButton">Sign in to Space</forms:button>
        <forms:button onclick="window.SpaceRepositoriesContentUpdater()">Refresh</forms:button>
        <forms:progressRing style="display:none; float: none; margin-left: 0.5em;" id="refreshProgress"/>
      </form>
    </div>
    <c:if test="${showMode ne 'popup'}">
      <script type="text/javascript">
        window.SpaceRepositoriesContentUpdater = function () {
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
          if (window.opener && window.opener.parent.SpaceRepositoriesContentUpdater) {
            window.opener.parent.SpaceRepositoriesContentUpdater();
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
    <script type="text/javascript">
      BS.Space = {
        repositories: new Map(),

        useRepository: function (repoId) {
          if ($j('#progress_' + repoId).is(":visible")) return; // double submit

          this.showProgress(repoId);

          const repo = this.repositories.get(repoId);
          $j('#createFromUrlForm input[name=credentialsMandatory]').val('');
          $j('#createFromUrlForm input[name=tokenType]').val('${tokenType}');
          $j('#createFromUrlForm input[name=tokenId]').val('${tokenId}');

          <c:choose>
          <c:when test="${showMode == 'createProjectMenu'}">
          $j('#createFromUrlForm input[name=url]').val(repo.url);
          $j('#createFromUrlForm input[name=objectType]').val("PROJECT");

          return BS.CreateFromUrlForm.submit();
          </c:when>
          <c:when test="${showMode == 'createBuildTypeMenu'}">
          $j('#createFromUrlForm input[name=url]').val(repo.url);
          $j('#createFromUrlForm input[name=objectType]').val("BUILD_TYPE");
          return BS.CreateFromUrlForm.submit();
          </c:when>
          <c:otherwise>
          if (!window.repositoryCallback) {
            alert("function window.repositoryCallback is not defined");
            return;
          }

          const projectId = '${project.externalId}';
          const connectionId = '<bs:forJs>${oauthProvider.id}</bs:forJs>';
          const tokenId = '<bs:forJs>${tokenId}</bs:forJs>';
          if (${isNonPersonalToken}) {
            const that = this;
            BS.SpaceTokenService.issueScopedProjectToken(projectId, connectionId, {
              onFailure(errorMessage) {
                that.hideProgress(repoId);
                BS.SpaceRepositoriesPopup.hidePopup();
                TeamCityAPI.Services.AlertService.addAlert(errorMessage);
              },
              onSuccess(tokenId) {
                that.invokeRepositoryCallback(repo, tokenId);
              }
            });
          } else {
            this.invokeRepositoryCallback(repo, tokenId)
          }

          </c:otherwise>
          </c:choose>
        },

        invokeRepositoryCallback(repo, tokenId) {
          if (repo != null) {
            var r = {
              repositoryUrl: repo.url,
              isPrivate: repo.isPrivate,
              name: repo.name,
            };
            var cre = {
              oauthLogin: '<c:out value="${oauthUsername}"/>',
              oauthProviderId: '<bs:forJs>${oauthProvider.id}</bs:forJs>',
              permanentToken: ${isPermanentToken},
              tokenType: '<bs:forJs>${tokenType}</bs:forJs>'
              <c:if test="${!isPermanentToken}">
              , tokenId: tokenId,
              teamcityName: '<bs:forJs>${teamcityName}</bs:forJs>',
              teamcityUsername: '<bs:forJs>${teamcityUsername}</bs:forJs>',
              connectionDisplayName: '<bs:forJs>${oauthProvider.connectionDisplayName}</bs:forJs>',
              acquiredNew: false
              </c:if>
            };
            <c:if test="${!isPermanentToken}">
            if (typeof acquiredNewToken !== 'undefined' && acquiredNewToken) {
              cre.acquiredNew = true;
            }
            </c:if>
            window.repositoryCallback(r, cre);
          }

          BS.SpaceRepositoriesPopup.hidePopup();
        },

        showProgress: function (repoId) {
          $j('#progress_' + repoId).show();
        },

        hideProgress: function (repoId) {
          $j('#progress_' + repoId).hide();
        },

        preselectRepository: function() {
          if (BS.SpacePreSelection.preSelectedRepositoryName) {
            for (const repo of this.repositories.values()) {
              if (repo.name === BS.SpacePreSelection.preSelectedRepositoryName){
                const menuItem = $j('#repoMenuItem_' + repo.id);
                menuItem.addClass('selected');
                menuItem.append($j('<div></div>', {
                  class: 'createBuildHint smallNote',
                  text: 'Click here to create a new Build Configuration'
                }));
                break;
              }
            }
          }
        }
      };

      <c:forEach items="${repositories}" var="repoGroup">
        <c:forEach items="${repoGroup.repositories}" var="repo" varStatus="pos">
          <c:set var="privateRepo" value='<%=((SpaceRepository)pageContext.getAttribute("repo")).isPrivate()%>'/>
          BS.Space.repositories.set('${repo.id}', {
            id: '${repo.id}',
            isPrivate: ${privateRepo},
            name: '<c:out value="${repo.name}"/>',
            url: '<c:out value="${repo.url}"/>',
          });
        </c:forEach>
      </c:forEach>

      $j(document).ready(function () {
        BS.Space.preselectRepository();
      });
    </script>
    <div>
      <c:set var="contId"><bs:id/></c:set>
      <c:if test="${repositoriesNum > 10}">
        <div class="grayNote reposCount">Found <strong>${repositoriesNum}</strong> <bs:plural txt="repository" val="${repositoriesNum}"/></div>
        <div class="filter">
          <bs:inplaceFilter containerId="${contId}" activate="true" filterText="&lt;filter repositories>"/>
        </div>
      </c:if>
      <c:if test="${repositoriesNum eq 0}">
        <c:choose>
          <c:when test="${isPendingConnection}">
            <%@include file="_pendingConnectionSupport.jspf"%>
          </c:when>
          <c:otherwise>
            <div>There are no repositories found.</div>
          </c:otherwise>
        </c:choose>
      </c:if>
      <c:if test="${repositoriesNum gt 0}">
        <ul id="${contId}" class="menuList">
          <c:forEach items="${repositories}" var="repoGroup">
            <li class="groupName">
              Repositories in "<c:out value="${repoGroup.projectName}"/>" project
              (${fn:length(repoGroup.repositories)})
            </li>
            <c:forEach items="${repoGroup.repositories}" var="repo" varStatus="pos">
              <c:set var="privateRepo" value='<%=((SpaceRepository)pageContext.getAttribute("repo")).isPrivate()%>'/>
              <li id="repoMenuItem_${repo.id}"
                  class="repository inplaceFiltered"
                  onclick="BS.Space.useRepository('${repo.id}')"
                  title="Click to use this repository" ${pos.last ? "style='margin-bottom: 1em;'" : ''}>
                <i class="repoStatus ${privateRepo ? 'icon-lock' : ''}"></i>
                <c:out value="${repo.name}"/> (<c:out value="${repo.url}"/>)
                <span id="progress_${repo.id}" class="useRepoProgress"><forms:progressRing/> Verifying connection...</span>
              </li>
            </c:forEach>
          </c:forEach>
        </ul>
      </c:if>
    </div>
    <jsp:include page="/oauth/createObjectFromUrlOfflineForm.jsp"/>
  </c:otherwise>
</c:choose>
