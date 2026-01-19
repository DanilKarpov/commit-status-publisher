<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="bitbucketError" type="jetbrains.buildServer.serverSide.oauth.bitbucket.BitBucketAccessTokenController.BitBucketError" scope="request"/>
<bs:externalPage>
  <jsp:attribute name="page_title">Bitbucket Request Error</jsp:attribute>
  <jsp:attribute name="head_include">
    <style type="text/css">
      div.mainContent {
        padding: 1em;
      }
    </style>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="mainContent">
      <h2>Bitbucket Request Error</h2>

      <c:choose>
        <c:when test="${bitbucketError.error == 'unauthorized_client'}">
          <p>
            Client ID and / or client secret specified in connection with name <strong><c:out value="${bitbucketError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out value="${bitbucketError.OAuthConnection.project.fullName}"/></strong>) are incorrect.
          </p>
        </c:when>
        <c:when test="${bitbucketError.error == 'access_denied'}">
          <p>
            TeamCity got access denied error on attempt to access your Bitbucket account.
          </p>
        </c:when>
        <c:otherwise>
          <p>
            <span class="error"><c:out value="${bitbucketError.errorDescription}"/><c:if test="${not fn:startsWith('teamcity_', bitbucketError.error)}"> (<c:out value="${bitbucketError.error}"/>)</c:if></span><br/>
            Connection: <strong><c:out value="${bitbucketError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out value="${bitbucketError.OAuthConnection.project.fullName}"/></strong>)
          </p>
        </c:otherwise>
      </c:choose>
    </div>
  </jsp:attribute>
</bs:externalPage>
