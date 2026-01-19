<%@ page import="jetbrains.buildServer.serverSide.oauth.azuredevops.AzureDevOpsAccessTokenController" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="azureDevOpsError" type="jetbrains.buildServer.serverSide.oauth.azuredevops.AzureDevOpsAccessTokenController.AzureDevOpsError" scope="request"/>
<jsp:useBean id="rootUrl" type="java.lang.String" scope="request"/>
<c:set var="callbackPath" value="<%=AzureDevOpsAccessTokenController.PATH%>"/>
<bs:externalPage>
  <jsp:attribute name="page_title">Azure DevOps Request Error</jsp:attribute>
  <jsp:attribute name="head_include">
    <style type="text/css">
      div.mainContent {
        padding: 1em;
      }
    </style>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="mainContent">
      <h2>Azure DevOps Request Error</h2>

      <c:choose>
        <c:when test="${azureDevOpsError.error == 'invalid_client'}">
          <p>
            Application ID and / or Client Secret specified in connection with name <strong><c:out value="${azureDevOpsError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out value="${azureDevOpsError.OAuthConnection.project.fullName}"/></strong>) are incorrect.
          </p>
        </c:when>
        <c:otherwise>
          <p>
            <span class="error"><c:out value="${azureDevOpsError.error}"/><c:if test="${not empty azureDevOpsError.errorDescription}">: <c:out value="${azureDevOpsError.errorDescription}"/></c:if></span>
            <c:if test="${not empty azureDevOpsError.OAuthConnection}">
              <br/>
              Connection: <strong><c:out value="${azureDevOpsError.OAuthConnection.connectionDisplayName}"/></strong> (project: <strong><c:out value="${azureDevOpsError.OAuthConnection.project.fullName}"/></strong>)
            </c:if>
          </p>
        </c:otherwise>
      </c:choose>
    </div>
  </jsp:attribute>
</bs:externalPage>
