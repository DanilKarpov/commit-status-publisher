<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.github.GitHubRepository" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp"%>
<%--@elvariable id="errorCode" type="java.lang.String"--%>
<%--@elvariable id="errorMessage" type="java.lang.String"--%>
<%--@elvariable id="oauthUsername" type="java.lang.String"--%>
<%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
<%--@elvariable id="repositories" type="java.util.List"--%>
<%--@elvariable id="repositoriesNum" type="java.lang.Integer"--%>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor" scope="request"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="showMode" type="java.lang.String" scope="request"/>
<c:set var="styles">
<bs:linkCSS>
  /css/forms.css
</bs:linkCSS>
<style type="text/css">
  #gitHubRepositories {
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

  ul.menuList li.repository {
    padding-left: 10px;
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

  ul.menuList li a {
    display: inline;
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
</style>
</c:set>
<c:choose>
  <c:when test="${errorCode == 'newTokenRequired'}">
    ${styles}
    <div>
      To show available repositories TeamCity requires access to your GitHub account.
      <br/>
      <br/>
      <iframe hidden id="iframe_${oauthProvider.id}">
        <script>
          window.GitHubRepositoriesContentUpdater = parent.GitHubRepositoriesContentUpdater;
        </script>
      </iframe>
      <c:set var="onclick">
        var iframe = document.getElementById('iframe_${oauthProvider.id}');
        var win = BS.Util.popupWindow(
          window['base_uri'] + '/oauth/github/repositories.html?projectId=${project.externalId}&connectionId=${oauthProvider.id}&updateToken=true&showMode=<%=WebUtil.encode(showMode)%>&userId=${currentUser.id}',
          'repositories_${oauthProvider.id}',
          {safe: false, opener: iframe.contentWindow}
        );
        var interval = window.setInterval(function() {
          try {
            if (win == null || win.closed) {
              window.clearInterval(interval);
              window.GitHubRepositoriesContentUpdater();
            }
          } catch (e) {
          }
        }, 1000);
      </c:set>
      <form id="signInButtons">
        <forms:button onclick="${onclick}" className="btn_primary submitButton">Sign in to GitHub</forms:button>
        <forms:button onclick="window.GitHubRepositoriesContentUpdater()">Refresh</forms:button>
        <forms:progressRing style="display:none; float: none; margin-left: 0.5em;" id="refreshProgress"/>
      </form>
    </div>
    <c:if test="${showMode ne 'popup'}">
      <script type="text/javascript">
        window.GitHubRepositoriesContentUpdater = function() {
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
      <jsp:attribute name="page_title">GitHub Authentication</jsp:attribute>
      <jsp:attribute name="head_include">
        ${styles}
        <script type="text/javascript">
          if (window.opener) {
            if (window.opener.parent.GitHubRepositoriesContentUpdater) {
              window.opener.parent.GitHubRepositoriesContentUpdater();
            }
            window.close();
          }
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
      BS.GitHub = {
        repositories: [],

        useRepository: function(repoId) {
          if ($j('#progress_' + repoId).is(":visible")) return; // double submit

          this.showProgress(repoId);

          var repo = this.repositories[repoId];
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

          if (repo != null) {
            var r = {
              repositoryUrl: repo.url,
              isPrivate: repo.isPrivate,
              owner: repo.owner,
              name: repo.name
            };
            var cre = {
              oauthLogin: '<c:out value="${oauthUsername}"/>',
              oauthProviderId: '${oauthProvider.id}',
              permanentToken: true
            };
            window.repositoryCallback(r, cre);

            BS.GitHubRepositoriesPopup.hidePopup();
          }
          </c:otherwise>
          </c:choose>
        },

        showProgress: function(repoId) {
          $j('#progress_' + repoId).show();
        }
      };

      <c:forEach items="${repositories}" var="repoGroup">
        <c:forEach items="${repoGroup.repositories}" var="repo">
        <c:set var="privateRepo" value='<%=((GitHubRepository)pageContext.getAttribute("repo")).isPrivate()%>'/>
        BS.GitHub.repositories[${repo.id}] = {
          url: '${repo.htmlUrl}',
          isPrivate: ${privateRepo},
          owner: '<c:out value="${repo.owner.login}"/>',
          name: '<c:out value="${repo.name}"/>'
        };
        </c:forEach>
      </c:forEach>
    </script>

    <c:set var="contId"><bs:id/></c:set>
    <c:if test="${repositoriesNum gt 10}">
    <div class="grayNote reposCount">Found <strong>${repositoriesNum}</strong> <bs:plural txt="repository" val="${repositoriesNum}"/></div>
    <div class="filter">
      <bs:inplaceFilter containerId="${contId}" activate="true" filterText="&lt;filter repositories>"/>
    </div>
    </c:if>
    <c:if test="${repositoriesNum eq 0}">
      <div>There are no repositories found.</div>
    </c:if>
    <c:if test="${repositoriesNum gt 0}">
    <ul id="${contId}" class="menuList">
      <c:forEach items="${repositories}" var="repoGroup">
        <%--@elvariable id="repoGroup" type="jetbrains.buildServer.serverSide.oauth.github.GitHubOAuthPopupControllerBase.RepositoryGroup"--%>
        <li class="groupName">
          <c:choose>
            <c:when test="${repoGroup.groupType eq 1}">Your repositories</c:when>
            <c:when test="${repoGroup.groupType eq 2}">Repositories owned by <strong><c:out value="${repoGroup.owner.login}"/></strong></c:when>
            <c:when test="${repoGroup.groupType eq 3}">Repositories owned by <strong><c:out value="${repoGroup.owner.login}"/></strong> organization</c:when>
          </c:choose>
          (${fn:length(repoGroup.repositories)})
        </li>
        <c:forEach items="${repoGroup.repositories}" var="repo" varStatus="repoPos">
          <c:set var="privateRepo" value='<%=((GitHubRepository)pageContext.getAttribute("repo")).isPrivate()%>'/>
          <li class="repository inplaceFiltered" onclick="BS.GitHub.useRepository(${repo.id})" title="Click to use this repository" ${repoPos.last ? "style='margin-bottom: 1em;'" : ''}>
            <i class="repoStatus ${privateRepo ? 'icon-lock' : ''}"></i>
            <c:out value="${repo.name}"/> (<c:out value="${repo.htmlUrl}"/>)
            <span id="progress_${repo.id}" class="useRepoProgress"><forms:progressRing/> Verifying connection...</span>
          </li>
        </c:forEach>
      </c:forEach>
    </ul>
    </c:if>
    <jsp:include page="/oauth/createObjectFromUrlOfflineForm.jsp"/>
  </c:otherwise>
</c:choose>
