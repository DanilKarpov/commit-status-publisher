<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp"%>
<%--@elvariable id="errorCode" type="java.lang.String"--%>
<%--@elvariable id="errorMessage" type="java.lang.String"--%>
<%--@elvariable id="oauthUsername" type="java.lang.String"--%>
<%--@elvariable id="isPermanentToken" type="java.lang.Boolean"--%>
<%--@elvariable id="tokenType" type="java.lang.String"--%>
<%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
<%--@elvariable id="repositories" type="java.util.List"--%>
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
  #azureDevOpsRepositories {
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
<script type="text/javascript">
  var acquiredNewToken = false;
</script>
<c:choose>
  <c:when test="${errorCode == 'newTokenRequired'}">
    ${styles}
    <div>
      To show available repositories, TeamCity requires access to your Azure DevOps account.
      <br/>
      <br/>
      <iframe hidden id="iframe_${oauthProvider.id}">
        <script>
          window.AzureDevOpsRepositoriesContentUpdater = parent.AzureDevOpsRepositoriesContentUpdater;
        </script>
      </iframe>
      <c:set var="onclick">
        acquiredNewToken = true;
        var iframe = document.getElementById('iframe_${oauthProvider.id}');
        var win = BS.Util.popupWindow(
          window['base_uri'] + '/oauth/azuredevops/repositories.html?projectId=${project.externalId}&connectionId=${oauthProvider.id}&updateToken=true&showMode=<%=WebUtil.encode(showMode)%>&userId=${currentUser.id}',
          'repositories_${oauthProvider.id}',
          {safe: false, opener: iframe.contentWindow}
        );
        var interval = window.setInterval(function() {
          try {
            if (win == null || win.closed) {
              window.clearInterval(interval);
              window.AzureDevOpsRepositoriesContentUpdater();
            }
          } catch (e) {
          }
        }, 1000);
      </c:set>
      <form id="signInButtons">
        <forms:button onclick="${onclick}" className="btn_primary submitButton">Sign in to Azure DevOps</forms:button>
        <forms:button onclick="window.AzureDevOpsRepositoriesContentUpdater()">Refresh</forms:button>
        <forms:progressRing style="display:none; float: none; margin-left: 0.5em;" id="refreshProgress"/>
      </form>
    </div>
    <c:if test="${showMode ne 'popup'}">
      <script type="text/javascript">
        window.AzureDevOpsRepositoriesContentUpdater = function() {
          $j('#refreshProgress').show();
          $j('#signInButtons a').attr('disabled', true);
          if (refreshCurrentContainer) refreshCurrentContainer();
        }
      </script>
    </c:if>
  </c:when>
  <c:when test="${errorCode == 'requestFailed'}">
    ${styles}
    <span class="errorMessage" style="white-space:pre"><c:out value="${errorMessage}"/></span>
  </c:when>
  <c:when test="${errorCode == 'tokenObtained'}">
    <bs:externalPage>
      <jsp:attribute name="page_title">Azure DevOps Authentication</jsp:attribute>
      <jsp:attribute name="head_include">
        ${styles}
        <script type="text/javascript">
          if (window.opener) {
            if (window.opener.parent.AzureDevOpsRepositoriesContentUpdater) {
              window.opener.parent.AzureDevOpsRepositoriesContentUpdater();
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
      BS.AzureDevOps = {
        repositories: [],

        useRepository: function(repoId) {
          if ($j('#progress_' + repoId).is(":visible")) return; // double submit

          this.showProgress(repoId);

          var repo = this.repositories[repoId];
          <c:choose>
          <c:when test="${showMode == 'createProjectMenu'}">
          $j('#createFromUrlForm input[name=url]').val(repo.url);
          $j('#createFromUrlForm input[name=objectType]').val("PROJECT");
          $j('#createFromUrlForm input[name=tokenType]').val('${tokenType}');
          return BS.CreateFromUrlForm.submit();
          </c:when>
          <c:when test="${showMode == 'createBuildTypeMenu'}">
          $j('#createFromUrlForm input[name=url]').val(repo.url);
          $j('#createFromUrlForm input[name=objectType]').val("BUILD_TYPE");
          $j('#createFromUrlForm input[name=tokenType]').val('${tokenType}');
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
              isPrivate: true,
              owner: repo.account,
              name: repo.project
            };
            var cre = {
              oauthLogin: '${oauthUsername}',
              oauthProviderId: '${oauthProvider.id}',
              permanentToken: ${isPermanentToken},
              tokenType: '${tokenType}',
              tokenId: '${tokenId}',
              teamcityName: '<bs:forJs>${teamcityName}</bs:forJs>',
              teamcityUsername: '<bs:forJs>${teamcityUsername}</bs:forJs>',
              connectionDisplayName: '<bs:forJs>${oauthProvider.connectionDisplayName}</bs:forJs>',
              acquiredNew: false
            };
            window.repositoryCallback(r, cre);

            BS.AzureDevOpsRepositoriesPopup.hidePopup();
          }
          </c:otherwise>
          </c:choose>
        },

        showProgress: function(repoId) {
          $j('#progress_' + repoId).show();
        }
      };

      <c:forEach items="${repositories}" var="repo">
      BS.AzureDevOps.repositories['${repo.id}'] = {
        type: '${repo.type}',
        account: '${repo.account}',
        project: '${repo.project}',
        url: '${repo.cloneUrl}'
      };
      </c:forEach>
    </script>

    <c:set var="reposNum" value="${fn:length(repositories)}"/>
    <c:set var="contId"><bs:id/></c:set>
    <div class="grayNote reposCount">Found <strong>${reposNum}</strong> <bs:plural txt="repository" val="${reposNum}"/></div>
    <c:if test="${reposNum > 10}">
    <div class="filter">
      <bs:inplaceFilter containerId="${contId}" activate="true" filterText="&lt;filter repositories>"/>
    </div>
    </c:if>
    <c:if test="${reposNum eq 0}">
      <div>There are no repositories found.</div>
    </c:if>
    <c:if test="${reposNum gt 0}">
    <ul id="${contId}" class="menuList">
      <c:forEach items="${repositories}" var="repo">
        <li class="inplaceFiltered" onclick="BS.AzureDevOps.useRepository('${repo.id}')" title="Click to use this repository">
          <i class="repoStatus icon-lock ${repo.type}"></i>
          <c:out value="${repo.account}"/>/<c:out value="${repo.project}"/> (<c:out value="${repo.type}"/>)
          <span id="progress_${repo.id}" class="useRepoProgress"><forms:progressRing/> Verifying connection...</span>
        </li>
      </c:forEach>
    </ul>
    </c:if>
    <jsp:include page="/oauth/createObjectFromUrlOfflineForm.jsp"/>
  </c:otherwise>
</c:choose>
