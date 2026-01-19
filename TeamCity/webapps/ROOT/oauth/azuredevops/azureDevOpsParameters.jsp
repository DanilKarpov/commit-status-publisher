<%@ include file="/include-internal.jsp"%>
<%@ page import="jetbrains.buildServer.serverSide.oauth.azuredevops.AzureDevOpsConstants" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.tfs.TfsAuthProvider" %>
<%@ page import="jetbrains.buildServer.serverSide.TeamCityProperties" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="oauthConnectionBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthProvider" scope="request"/>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>
<c:set var="azureDevOpsRepositoryEnabled" value="<%= TeamCityProperties.getBooleanOrTrue(AzureDevOpsConstants.OAUTH_AZUREDEVOPS_REPOSITORY_ENABLED_PROP) %>"/>
<%--@elvariable id="redirectUrl" type="java.lang.String"--%>
<%--@elvariable id="redirectUrlUnique" type="java.lang.String"--%>
<%--@elvariable id="redirectUrlFallback" type="java.lang.String"--%>
<%--@elvariable id="isNewConnection" type="java.lang.Boolean"--%>


<style type="text/css">
  tr.azureDevOpsNote table {
    width: 100%;
    border-spacing: 0;
  }

  tr.azureDevOpsNote table td {
    border: none;
  }

  table.applicationUrls {
    padding: 4px;
    border-collapse: collapse;
  }

  table.applicationUrls tr {
    margin-bottom: 10px;
  }

  .azureScopes {
    padding-inline-start: 12px;
    margin-top: 0px;
  }

  table.applicationUrls td:first-child {
    width: 13em;
  }

  #azureDevOpsWebsitel {
    width: 24em;
  }

  #azureDevOpsCallbackUrl {
    width: 24em;
  }
</style>
<c:if test="${empty oauthConnectionBean.connectionId}">
<tr class="azureDevOpsNote">
  <td colspan="2">
    <div class="attentionComment">
      Use this connection type to access Git repositories and authenticate Azure users in TeamCity.
      To access TFVC projects, use the Azure DevOps PAT connection type.<bs:help file="Connecting+to+Azure+DevOps"/>

      <a href="https://app.vsaex.visualstudio.com/app/register" target="_blank" rel="noreferrer">Register an OAuth application in Azure DevOps</a> using the following parameters:<br />
      <oauth:urlTable>
        <oauth:urlTableRow caption="Application website">
          <oauth:redirectUrl id="azureDevOpsWebsitel" value="${rootUrl}"/>
        </oauth:urlTableRow>
        <oauth:urlTableRow caption="Authorization callback URL">
          <oauth:redirectUrl id="azureDevOpsCallbackUrl" value="${redirectUrl}"/>
        </oauth:urlTableRow>
        <tr>
          <td>Authorized scopes:</td>
          <td>
            <details open>
              <summary><strong>Minimal required scopes</strong></summary>
              Identity (read), Project and team (read), Code (read)
            </details>
            <details>
              <summary><strong>Scopes recommended for status publishing</strong></summary>
              Identity (read), Project and team (read), Code (status)
            </details>
            <details>
              <summary><strong>Scopes recommended for status publishing, VCS labeling, merging, and versioned settings</strong></summary>
              Identity (read), Project and team (read), Code (read and write)
            </details>
          </td>
        </tr>
      </oauth:urlTable>
      <br/>
      Enter the <b>Server URL</b>, <b>App ID</b>, and <b>Client Secret</b> in the form below.
    </div>
  </td>
</tr>
</c:if>
<oauth:displayName style="width: 25em;"/>
<tr>
  <th><label for="<%=AzureDevOpsConstants.SERVER_URL_PARAM%>">Server URL:</label><l:star/></th>
  <td>
    <props:textProperty name="<%=AzureDevOpsConstants.SERVER_URL_PARAM%>" style="width: 25em;"/>
    <span class="smallNote">E.g. https://app.vssps.visualstudio.com</span>
    <span class="error" id="error_azureDevOpsUrl"></span>
  </td>
</tr>
<tr>
  <th><label for="<%=AzureDevOpsConstants.APP_ID_PARAM%>">App ID:</label><l:star/></th>
  <td>
    <props:textProperty name="<%=AzureDevOpsConstants.APP_ID_PARAM%>" style="width: 25em;"/>
    <span class="error" id="error_<%=AzureDevOpsConstants.APP_ID_PARAM%>"></span>
  </td>
</tr>
<tr>
  <th><label for="<%=AzureDevOpsConstants.CLIENT_SECRET_PARAM%>">Client secret:</label><l:star/></th>
  <td>
    <props:passwordProperty name="<%=AzureDevOpsConstants.CLIENT_SECRET_PARAM%>" style="width: 25em;"/>
    <span class="error" id="error_secure:clientSecret"></span>
  </td>
</tr>
<tr>
  <th><label for="<%=AzureDevOpsConstants.CLIENT_SECRET_PARAM%>">Authorized scopes:</label></th>
  <td>
    <props:textProperty name="<%=AzureDevOpsConstants.SCOPE_PARAM%>" style="width: 25em;"/>
    <span class="smallNote">Copy from the Azure DevOps OAuth App. Defaults to <b>vso.identity vso.code vso.project</b>.
      <a target="_blank" rel="noreferrer" href="https://learn.microsoft.com/en-us/azure/devops/integrate/get-started/authentication/oauth?view=azure-devops#scopes"><bs:helpIcon/></a></span>
    <span class="error" id="error_<%=AzureDevOpsConstants.SCOPE_PARAM%>"></span>
  </td>
</tr>
<oauth:uniqueRedirectCheckbox
    project="${project}"
    connectionBean="${oauthConnectionBean}"
    oauthProvider="${oauthProvider}"
    urlElement="azureDevOpsCallbackUrl"
    initialUrl="${redirectUrl}"
    uniqueUrl="${redirectUrlUnique}"
    fallbackUrl="${redirectUrlFallback}"
    providerDisplayName="Azure"
    isNewConnection="${isNewConnection}"
    urlName="callback"
/>
