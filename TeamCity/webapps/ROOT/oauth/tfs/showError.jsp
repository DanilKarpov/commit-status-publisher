<%@ page import="jetbrains.buildServer.serverSide.oauth.tfs.TfsAccessTokenController" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="tfsError" type="jetbrains.buildServer.serverSide.oauth.tfs.TfsAccessTokenController.TfsError" scope="request"/>
<jsp:useBean id="rootUrl" type="java.lang.String" scope="request"/>
<c:set var="callbackPath" value="<%=TfsAccessTokenController.PATH%>"/>
<bs:externalPage>
  <jsp:attribute name="page_title">TFS Request Error</jsp:attribute>
  <jsp:attribute name="head_include">
    <style type="text/css">
      div.mainContent {
        padding: 1em;
      }
    </style>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="mainContent">
      <h2>TFS Request Error</h2>

      <c:choose>
        <c:when test="${tfsError.error == 'incorrect_client_credentials'}">
          <p>
            Client ID and / or client secret specified in connection with name <strong><c:out value="${tfsError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out value="${tfsError.OAuthConnection.project.fullName}"/></strong>) are incorrect.
          </p>
        </c:when>
        <c:when test="${tfsError.error == 'redirect_uri_mismatch'}">
          <p>
            Invalid callback URL specified in TFS OAuth application. Callback URL should be:
            <span id="tfsCallbackUrl"><c:out value="${rootUrl}${callbackPath}"/></span> <span class="clipboard-btn tc-icon icon16 tc-icon_copy" data-clipboard-action="copy" data-clipboard-target="#tfsCallbackUrl"></span>
            <script type="text/javascript">
              BS.Clipboard('.clipboard-btn');
            </script>
          </p>
        </c:when>
        <c:when test="${tfsError.error == 'InvalidScope'}">
          <p>
            Requested invalid scope to grant permissions for OAuth application.
          </p>
        </c:when>
        <c:otherwise>
          <p>
            <span class="error"><c:out value="${tfsError.error}"/><c:if test="${not empty tfsError.errorDescription}">: <c:out value="${tfsError.errorDescription}"/></c:if></span>
            <c:if test="${not empty tfsError.OAuthConnection}">
              <br/>
              Connection: <strong><c:out value="${tfsError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out value="${tfsError.OAuthConnection.project.fullName}"/></strong>)
            </c:if>
          </p>
        </c:otherwise>
      </c:choose>
    </div>
  </jsp:attribute>
</bs:externalPage>
