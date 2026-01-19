<%@ taglib prefix="props" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.github.GitHubAccessTokenController" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.github.GitHubConstants" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="oauthConnectionBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthProvider" scope="request"/>
<c:set var="callbackPath" value="<%=GitHubAccessTokenController.PATH%>"/>
<c:set var="defaultTokenScopeParam" value="<%=GitHubConstants.DEFAULT_TOKEN_SCOPE_PARAM%>"/>
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
    border: none;
  }
</style>
<c:if test="${empty oauthConnectionBean.connectionId}">
<tr class="githubNote">
  <td colspan="2">
    <div class="attentionComment">
      <c:choose>
        <c:when test="${oauthConnectionBean.providerType == 'GitHub'}">
          Please <a href="https://github.com/settings/applications/new" target="_blank" rel="noreferrer">register TeamCity</a> on GitHub using the following parameters:<br/>
        </c:when>
        <c:otherwise>
          Please register TeamCity OAuth application on GitHub Enterprise server using the following parameters:<br/>
        </c:otherwise>
      </c:choose>
      <oauth:urlTable>
        <oauth:urlTableRow caption="Homepage URL">
          <oauth:redirectUrl id="githubHomepageUrl" value="${rootUrl}"/>
        </oauth:urlTableRow>
        <oauth:urlTableRow caption="Authorization callback URL">
          <oauth:redirectUrl id="githubCallbackUrl" value="${redirectUrl}"/>
        </oauth:urlTableRow>
      </oauth:urlTable>
      <br/>
      <c:choose>
        <c:when test="${oauthConnectionBean.providerType == 'GitHub'}">
          And once registered, enter the <strong>client id</strong> and the <strong>client secret</strong> in the form below.
        </c:when>
        <c:otherwise>
          And once registered, enter the <strong>GitHub server URL</strong>, the <strong>client id</strong> and the <strong>client secret</strong> in the form below.
        </c:otherwise>
      </c:choose>
    </div>
  </td>
</tr>
</c:if>
<oauth:displayName />
<c:choose>
  <c:when test="${oauthConnectionBean.providerType == 'GitHub'}">
  <tr>
    <td colspan="2" style="border: none; padding: 0; border-spacing: 0"><props:hiddenProperty name="gitHubUrl" /></td>
  </tr>
  </c:when>
  <c:otherwise>
    <tr>
      <th><label for="gitHubUrl">Server URL:</label><l:star/></th>
      <td>
        <props:textProperty name="gitHubUrl" className="longField"/>
        <span class="error" id="error_gitHubUrl"></span>
      </td>
    </tr>
  </c:otherwise>
</c:choose>
<tr>
  <th><label for="clientId">Client ID:</label><l:star/></th>
  <td>
    <props:textProperty name="clientId" className="longField"/>
    <span class="error" id="error_clientId"></span>
  </td>
</tr>
<tr>
  <th><label for="secure:clientSecret">Client secret:</label><l:star/></th>
  <td>
    <props:passwordProperty name="secure:clientSecret" className="longField"/>
    <span class="error" id="error_secure:clientSecret"></span>

    <input type="hidden" name="prop:${defaultTokenScopeParam}" value="${propertiesBean.properties[defaultTokenScopeParam]}"/>
  </td>
</tr>
<c:if test="${oauthConnectionBean.providerType == 'GHE'}">
  <oauth:uniqueRedirectCheckbox
      project="${project}"
      connectionBean="${oauthConnectionBean}"
      oauthProvider="${oauthProvider}"
      urlElement="githubCallbackUrl"
      initialUrl="${redirectUrl}"
      uniqueUrl="${redirectUrlUnique}"
      fallbackUrl="${redirectUrlFallback}"
      providerDisplayName="GitHub"
      isNewConnection="${isNewConnection}"
      urlName="callback"
  />
</c:if>