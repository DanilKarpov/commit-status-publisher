<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="gitlabError" type="jetbrains.buildServer.serverSide.oauth.gitlab.GitLabError" scope="request"/>
<bs:externalPage>
  <jsp:attribute name="page_title">GitLab Request Error</jsp:attribute>
  <jsp:attribute name="head_include">
    <style type="text/css">
      div.mainContent {
        padding: 1em;
      }
    </style>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="mainContent">
      <h2>GitLab Request Error</h2>

      <c:choose>
        <c:when test="${gitlabError.error == 'unauthorized_client'}">
          <p>
            Client ID and / or client secret specified in connection with name <strong><c:out value="${gitlabError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out value="${gitlabError.OAuthConnection.project.fullName}"/></strong>) are incorrect.
          </p>
        </c:when>
        <c:when test="${gitlabError.error == 'access_denied'}">
          <p>
            TeamCity got access denied error on attempt to access your GitLab account.
          </p>
        </c:when>
        <c:otherwise>
          <p>
            <span class="error"><c:out value="${gitlabError.errorDescription}"/><c:if test="${not fn:startsWith('teamcity_', gitlabError.error)}"> (<c:out value="${gitlabError.error}"/>)</c:if></span><br/>
            Connection: <strong><c:out value="${gitlabError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out value="${gitlabError.OAuthConnection.project.fullName}"/></strong>)
          </p>
        </c:otherwise>
      </c:choose>
    </div>
  </jsp:attribute>
</bs:externalPage>
