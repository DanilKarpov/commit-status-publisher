<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="cons" class="jetbrains.buildServer.serverSide.oauth.tfs.TfsConstants"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="oauthConnectionBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>

<c:if test="${empty oauthConnectionBean.connectionId}">
<tr class="tfsNote">
  <td colspan="2">
    <div class="attentionComment">
      This type of connection relies on personal access tokens.
      <br/><br/>
      Please <a href="https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate#create-personal-access-tokens-to-authenticate-access" target="_blank" rel="noreferrer">create a personal token</a> in your account with the <b>All scopes</b> option.
      <br/>
      After that, enter the <b>Server URL</b> and <b>Access Token</b> in the form below.
    </div>
  </td>
</tr>
</c:if>

<tr>
  <th><label for="${cons.serverUrl}">Server URL:</label><l:star/></th>
  <td>
    <props:textProperty name="${cons.serverUrl}" className="longField"/>
    <span class="error" id="error_${cons.serverUrl}"></span>
    <span class="smallNote">
      URL format:<br/>
      <%--TFS: http[s]://&lt;host&gt;[:&lt;port&gt;]/tfs/&lt;collection&gt;<br/>--%>
      Azure DevOps: https://dev.azure.com/&lt;organization&gt;<br/>
      VSTS: https://&lt;account&gt;.visualstudio.com
    </span>
  </td>
</tr>
<tr>
  <th><label for="${cons.accessToken}">Access token:</label><l:star/></th>
  <td>
    <props:passwordProperty name="${cons.accessToken}" className="longField"/>
    <span class="error" id="error_${cons.accessToken}"></span>
  </td>
</tr>