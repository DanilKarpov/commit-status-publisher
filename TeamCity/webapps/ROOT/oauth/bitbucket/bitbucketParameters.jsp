<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="oauthConnectionBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>

<style type="text/css">
  tr.githubNote table {
    width: 100%;
    border-spacing: 0;
  }

  tr.githubNote table td {
    border: none;
  }

  table.applicationUrls {
    padding: 4px;
  }

  table.applicationUrls tr td details {
    margin-left: 10px;
  }
</style>
<c:if test="${empty oauthConnectionBean.connectionId}">
<tr class="githubNote">
  <td colspan="2">
    <div class="attentionComment">
      Register an OAuth consumer on <a href="https://bitbucket.org/" target="_blank" rel="noreferrer">Bitbucket Cloud</a> using the following parameters:<br/>
      <br/>
      <oauth:urlTable>
        <oauth:urlTableRow caption="URL">
          <oauth:redirectUrl id="bitbucketHomeUrl" value="${rootUrl}"/>
        </oauth:urlTableRow>
        <oauth:urlTableRow caption="Callback URL">
          <oauth:redirectUrl id="bitbucketCallbackUrl" value="${rootUrl}/oauth/bitbucket/"/>
        </oauth:urlTableRow>
        <tr>
          <td>Permissions required for specific features:</td>
          <td>
            <details open>
              <summary><strong>Authenticating in TeamCity via Bitbucket Cloud</strong></summary>
              Account: Read
            </details>
            <details open>
              <summary><strong>Creating a Project from Bitbucket Cloud</strong></summary>
              Repositories: Read
            </details>
            <details open>
              <summary><strong>VCS labeling, merging and versioned settings</strong></summary>
              Repositories: Write
            </details>
            <details open>
              <summary><strong>Pull Requests build feature</strong></summary>
              Pull requests: Read
            </details>
            <details open>
              <summary><strong>Commit Status Publisher build feature</strong></summary>
              Repositories: Read
            </details>
          </td>
        </tr>
      </oauth:urlTable><br/>
      Copy from Bitbucket cloud the <strong>key</strong> and the <strong>secret</strong> and enter them in the form below.
    </div>
  </td>
</tr>
</c:if>
<oauth:displayName style="width: 25em;"/>
<tr>
  <th><label for="clientId">Key:</label><l:star/></th>
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
