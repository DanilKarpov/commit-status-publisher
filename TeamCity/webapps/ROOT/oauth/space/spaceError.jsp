<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="spaceError" type="jetbrains.buildServer.serverSide.oauth.space.pojo.SpaceError" scope="request"/>
<bs:externalPage>
  <jsp:attribute name="page_title">Space Request Error</jsp:attribute>
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
        <c:when test="${spaceError.error == 'unauthorized_client'}">
          <p>
            The application is not authorized to request an authorization code via <strong><c:out value="${spaceError.OAuthConnection.connectionDisplayName}"/></strong> (project:
            <strong><c:out value="${spaceError.OAuthConnection.project.fullName}"/></strong>) (Credentials are incorrect).
          </p>
        </c:when>
        <c:when test="${spaceError.error == 'access_denied'}">
          <p>
            Login rejected on the Space side. (<strong><c:out value="${spaceError.OAuthConnection.connectionDisplayName}"/></strong>)
          </p>
        </c:when>
        <c:when test="${spaceError.error == 'invalid_scope'}">
          <p>
            The requested scope is invalid, unknown, or malformed. (<strong><c:out value="${spaceError.OAuthConnection.connectionDisplayName}"/></strong>)
          </p>
        </c:when>
        <c:when test="${spaceError.error == 'invalid_request'}">
          <p>
            The request is missing a required parameter, includes an invalid parameter value, includes a parameter more than once, or is otherwise malformed.
            (<strong><c:out value="${spaceError.OAuthConnection.connectionDisplayName}"/></strong>)
          </p>
        </c:when>
        <c:otherwise>
          <p>
            <span class="error"><c:out value="${spaceError.errorDescription}"/><c:if test="${not fn:startsWith('teamcity_', spaceError.error)}"> (<c:out
                value="${spaceError.error}"/>)</c:if></span><br/>
            Connection: <strong><c:out value="${spaceError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out
              value="${spaceError.OAuthConnection.project.fullName}"/></strong>)
          </p>
        </c:otherwise>
      </c:choose>
    </div>
  </jsp:attribute>
</bs:externalPage>
