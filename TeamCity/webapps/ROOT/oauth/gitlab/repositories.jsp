<%@ page import="jetbrains.buildServer.serverSide.oauth.gitlab.GitLabRepository" %>
<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp"%>
<%--@elvariable id="errorCode" type="java.lang.String"--%>
<%--@elvariable id="vcsType" type="java.lang.String"--%>
<%--@elvariable id="errorMessage" type="java.lang.String"--%>
<%--@elvariable id="oauthUsername" type="java.lang.String"--%>
<%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
<%--@elvariable id="repositories" type="java.util.List<jetbrains.buildServer.serverSide.oauth.gitlab.GitLabRepositoryOwner>"--%>
<%--@elvariable id="repositoriesNum" type="java.lang.Integer"--%>
<%--@elvariable id="tokenType" type="java.lang.String"--%>
<%--@elvariable id="tokenId" type="java.lang.String"--%>
<%--@elvariable id="teamcityName" type="java.lang.String"--%>
<%--@elvariable id="teamcityUsername" type="java.lang.String"--%>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor" scope="request"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="showMode" type="java.lang.String" scope="request"/>
<c:set var="styles">
  <bs:linkCSS>
    /css/forms.css
  </bs:linkCSS>
  <style type="text/css">
    #gitlabRepositories {
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
  </style>
</c:set>
<script type="text/javascript">
  var acquiredNewToken = false;
</script>
<c:choose>
  <c:when test="${errorCode == 'newTokenRequired'}">
    ${styles}
    <div>
      To show available repositories TeamCity requires access to your <a href="https://gitlab.com/" target="_blank" rel="noreferrer">GitLab</a> account.
      <br/>
      <br/>
      <iframe hidden id="iframe_${oauthProvider.id}">
        <script>
          window.GitLabRepositoriesContentUpdater = parent.GitLabRepositoriesContentUpdater;
        </script>
      </iframe>
      <c:set var="onclick">
        acquiredNewToken = true;
        var iframe = document.getElementById('iframe_${oauthProvider.id}');
        var win = BS.Util.popupWindow(
          window['base_uri'] + '/oauth/gitlab/repositories.html?projectId=${project.externalId}&connectionId=${oauthProvider.id}&vcsType=${vcsType}&updateToken=true&showMode=<%=WebUtil.encode(showMode)%>&userId=${currentUser.id}',
          'repositories_${oauthProvider.id}',
          {safe: false, opener: iframe.contentWindow}
        );
        var interval = window.setInterval(function() {
          try {
            if (win == null || win.closed) {
              window.clearInterval(interval);
              window.GitLabRepositoriesContentUpdater();
            }
          } catch (e) {
          }
        }, 1000);
      </c:set>
      <form id="signInButtons">
        <forms:button onclick="${onclick}" className="btn_primary submitButton">Sign in to GitLab</forms:button>
        <forms:button onclick="window.GitLabRepositoriesContentUpdater()">Refresh</forms:button>
        <forms:progressRing style="display:none; float: none; margin-left: 0.5em;" id="refreshProgress"/>
      </form>
    </div>
    <c:if test="${showMode ne 'popup'}">
      <script type="text/javascript">
        window.GitLabRepositoriesContentUpdater = function() {
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
      <jsp:attribute name="page_title">GitLab Authentication</jsp:attribute>
      <jsp:attribute name="head_include">
        ${styles}
        <script type="text/javascript">
          if (window.opener && window.opener.parent.GitLabRepositoriesContentUpdater) {
            window.opener.parent.GitLabRepositoriesContentUpdater();
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
      BS.GitLab = {
        repositories: [],

        useRepository: function(repoId) {
          if ($j('#progress_' + repoId).is(":visible")) return; // double submit

          this.showProgress(repoId);

          var repo = this.repositories[repoId];
          if (repo.isPrivate) {
            $j('#createFromUrlForm input[name=credentialsMandatory]').val('true');
          } else {
            $j('#createFromUrlForm input[name=credentialsMandatory]').val('');
          }
          $j('#createFromUrlForm input[name=tokenType]').val('${tokenType}');

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
              name: repo.name,
              htmlUrl: repo.htmlUrl
            };
            var cre = {
              oauthLogin: '<c:out value="${oauthUsername}"/>',
              oauthProviderId: '${oauthProvider.id}',
              permanentToken: false,
              tokenType: '<bs:forJs>${tokenType}</bs:forJs>',
              tokenId: '${tokenId}',
              teamcityName: '<bs:forJs>${teamcityName}</bs:forJs>',
              teamcityUsername: '<bs:forJs>${teamcityUsername}</bs:forJs>',
              connectionDisplayName: '<bs:forJs>${oauthProvider.connectionDisplayName}</bs:forJs>',
              acquiredNew: false
            };
            if (typeof acquiredNewToken !== 'undefined' && acquiredNewToken) {
              cre.acquiredNew = true;
            }
            window.repositoryCallback(r, cre);
          }

          BS.GitLabRepositoriesPopup.hidePopup();
          </c:otherwise>
          </c:choose>
        },

        showProgress: function(repoId) {
          $j('#progress_' + repoId).show();
        }
      };

      <c:forEach items="${repositories}" var="repoGroup">
        <c:forEach items="${repoGroup.repositories}" var="repo" varStatus="pos">
        <c:set var="privateRepo" value='<%=((GitLabRepository)pageContext.getAttribute("repo")).isPrivate()%>'/>
        BS.GitLab.repositories['${repo.id}'] = {
          url: '${repo.httpCloneUrl}',
          isPrivate: ${privateRepo},
          name: '<c:out value="${repo.name}"/>',
          owner: '<c:out value="${repo.owner}"/>',
          htmlUrl: '${repo.htmlUrl}'
        };
        </c:forEach>
      </c:forEach>
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
        <div>There are no repositories found.</div>
      </c:if>
      <c:if test="${repositoriesNum gt 0}">
      <ul id="${contId}" class="menuList">
        <c:forEach items="${repositories}" var="repoGroup">
          <li class="groupName">
            Repositories owned by <strong><c:out value="${repoGroup.owner}"/></strong>
            (${fn:length(repoGroup.repositories)})
          </li>
          <c:forEach items="${repoGroup.repositories}" var="repo" varStatus="pos">
          <c:set var="privateRepo" value='<%=((GitLabRepository)pageContext.getAttribute("repo")).isPrivate()%>'/>
          <li class="repository inplaceFiltered" onclick="BS.GitLab.useRepository('${repo.id}')" title="Click to use this repository" ${pos.last ? "style='margin-bottom: 1em;'" : ''}>
            <i class="repoStatus ${privateRepo ? 'icon-lock' : ''}"></i>
            <c:out value="${repo.name}"/> (<c:out value="${repo.htmlUrl}"/>)
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
