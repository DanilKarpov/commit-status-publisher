<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="oauthConnectionBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthProvider" scope="request"/>
<%--@elvariable id="redirectUrl" type="java.lang.String"--%>
<%--@elvariable id="redirectUrlUnique" type="java.lang.String"--%>
<%--@elvariable id="redirectUrlFallback" type="java.lang.String"--%>
<%--@elvariable id="isNewConnection" type="java.lang.Boolean"--%>

<style type="text/css">
  tr.githubNote table {
    width: 100%;
    border-spacing: 0;
  }

  tr.githubNote table td {
    padding: 1px 0 1px 0;
    border: none;
  }

  table.applicationUrls {
    padding: 4px;
  }
</style>
<c:if test="${empty oauthConnectionBean.connectionId}">
<tr class="gitlabNote">
  <td colspan="2">
    <div class="attentionComment">
      <c:choose>
          <c:when test="${oauthConnectionBean.providerType == 'GitLabCEorEE'}">
            Please register OAuth application on GitLab using the following parameters:<br/>
          </c:when>
          <c:otherwise>
            Please <a href="https://gitlab.com/-/profile/applications" target="_blank" rel="noreferrer">register OAuth application</a> on GitLab using the following parameters:<br/>
          </c:otherwise>
      </c:choose>
      <oauth:urlTable>
        <oauth:urlTableRow caption="Redirect URL">
          <oauth:redirectUrl id="gitlabCallbackUrl" value="${redirectUrl}"/>
        </oauth:urlTableRow>
        <tr>
          <td>Minimal scope:</td>
          <td><strong>api</strong></td>
        </tr>
      </oauth:urlTable><br/>

      And once registered, enter the <strong>Application ID</strong> and the <strong>Secret</strong> in the form below.
    </div>
  </td>
</tr>
</c:if>
<oauth:displayName style="width: 25em;"/>
<c:if test="${oauthConnectionBean.providerType == 'GitLabCEorEE'}">
  <tr>
    <th><label for="gitHubUrl">Server URL:</label><l:star/></th>
    <td>
      <props:textProperty name="gitLabUrl" style="width: 25em;"/>
      <span class="error" id="error_gitLabUrl"></span>
    </td>
  </tr>
</c:if>
<tr>
  <th><label for="clientId">Application ID:</label><l:star/></th>
  <td>
    <props:textProperty name="clientId" style="width: 25em;"/>
    <span class="error" id="error_clientId"></span>
  </td>
</tr>
<tr>
  <th><label for="secure:clientSecret">Secret:</label><l:star/></th>
  <td>
    <props:passwordProperty name="secure:clientSecret" style="width: 25em;"/>
    <span class="error" id="error_secure:clientSecret"></span>
  </td>
</tr>
<oauth:uniqueRedirectCheckbox
    project="${project}"
    connectionBean="${oauthConnectionBean}"
    oauthProvider="${oauthProvider}"
    urlElement="gitlabCallbackUrl"
    initialUrl="${redirectUrl}"
    uniqueUrl="${redirectUrlUnique}"
    fallbackUrl="${redirectUrlFallback}"
    providerDisplayName="GitLab"
    isNewConnection="${isNewConnection}"
/>