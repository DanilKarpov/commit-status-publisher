<%@ page import="jetbrains.buildServer.serverSide.oauth.github.GitHubAccessTokenController" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="githubError" type="jetbrains.buildServer.serverSide.oauth.github.GitHubAccessTokenController.GitHubError" scope="request"/>
<jsp:useBean id="rootUrl" type="java.lang.String" scope="request"/>
<jsp:useBean id="callbackPath" type="java.lang.String" scope="request"/>
<bs:externalPage>
  <jsp:attribute name="page_title">GitHub Request Error</jsp:attribute>
  <jsp:attribute name="head_include">
    <style type="text/css">
      div.mainContent {
        padding: 1em;
      }
    </style>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="mainContent">
      <h2>GitHub Request Error</h2>

      <c:choose>
        <c:when test="${githubError.error == 'incorrect_client_credentials'}">
          <p>
            Client ID and / or client secret specified in connection with name <strong><c:out value="${githubError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out value="${githubError.OAuthConnection.project.fullName}"/></strong>) are incorrect.
          </p>
        </c:when>
        <c:when test="${githubError.error == 'redirect_uri_mismatch'}">
          <p>
            Invalid authorization callback URL specified in GitHub OAuth application.
            <c:if test="${not empty callbackPath}">
              Callback URL should be:
              <span id="githubCallbackUrl"><c:out value="${rootUrl}${callbackPath}"/></span> <span class="clipboard-btn tc-icon icon16 tc-icon_copy" data-clipboard-action="copy" data-clipboard-target="#githubCallbackUrl"></span>
              <script type="text/javascript">
                BS.Clipboard('.clipboard-btn');
              </script>
            </c:if>
          </p>
        </c:when>
        <c:otherwise>
          <p>
            <span class="error"><c:out value="${githubError.errorDescription}"/> (<c:out value="${githubError.error}"/>)</span>
            <c:if test="${not empty githubError.OAuthConnection}">
              <br/>
              Connection: <strong><c:out value="${githubError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out value="${githubError.OAuthConnection.project.fullName}"/></strong>)
            </c:if>
          </p>
        </c:otherwise>
      </c:choose>
    </div>
  </jsp:attribute>
</bs:externalPage>
