<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="googleError" type="jetbrains.buildServer.serverSide.oauth.google.pojo.GoogleError" scope="request"/>
<bs:externalPage>
  <jsp:attribute name="page_title">Google Request Error</jsp:attribute>
  <jsp:attribute name="head_include">
    <style type="text/css">
      div.mainContent {
        padding: 1em;
      }
    </style>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="mainContent">
      <h2>Space Request Error</h2>

      <c:choose>
        <c:when test="${googleError.error == 'unauthorized_client'}">
          <p>
            The application is not authorized to request an authorization code via <strong><c:out value="${googleError.OAuthConnection.connectionDisplayName}"/></strong> (project:
            <strong><c:out value="${googleError.OAuthConnection.project.fullName}"/></strong>) (Credentials are incorrect).
          </p>
        </c:when>
        <c:when test="${googleError.error == 'access_denied'}">
          <p>
            Login rejected on the Google side. (<strong><c:out value="${googleError.OAuthConnection.connectionDisplayName}"/></strong>)
          </p>
        </c:when>
        <c:when test="${googleError.error == 'invalid_scope'}">
          <p>
            The requested scope is invalid, unknown, or malformed. (<strong><c:out value="${googleError.OAuthConnection.connectionDisplayName}"/></strong>)
          </p>
        </c:when>
        <c:when test="${googleError.error == 'invalid_request'}">
          <p>
            The request is missing a required parameter, includes an invalid parameter value, includes a parameter more than once, or is otherwise malformed.
            (<strong><c:out value="${googleError.OAuthConnection.connectionDisplayName}"/></strong>)
          </p>
        </c:when>
        <c:otherwise>
          <p>
            <span class="error"><c:out value="${googleError.errorDescription}"/><c:if test="${not fn:startsWith('teamcity_', googleError.error)}"> (<c:out
                value="${googleError.error}"/>)</c:if></span><br/>
            Connection: <strong><c:out value="${googleError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out
              value="${googleError.OAuthConnection.project.fullName}"/></strong>)
          </p>
        </c:otherwise>
      </c:choose>
    </div>
  </jsp:attribute>
</bs:externalPage>
