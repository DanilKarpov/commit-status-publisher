<%@ page import="jetbrains.buildServer.serverSide.oauth.google.GoogleAccessTokenController" %>
<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ page import="jetbrains.buildServer.serverSide.TeamCityProperties" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.google.GoogleConstants" %>

<jsp:useBean id="keys" class="jetbrains.buildServer.serverSide.oauth.google.GoogleOAuthKeys"/>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout" %>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>
<%@ include file="/include-internal.jsp" %>

<c:set var="currentRootUrl" value="${WebUtil.getRootUrl(pageContext.request)}"/>
<jsp:useBean id="rootUrl" type="java.lang.String" scope="request"/>

<c:set var="currentGoogleRootUrl" value="${WebUtil.getRootUrl(pageContext.request)}${GoogleAccessTokenController.PATH}"/>
<c:set var="googleRootUrl" value="${rootUrl}${GoogleAccessTokenController.PATH}"/>

<style type="text/css">
  tr.googleNote table {
    width: 100%;
    border-spacing: 0;
  }

  tr.googleNote table td {
    padding: 1px 0 1px 0;
    border: none;
  }

  table.applicationUrls {
    padding: 4px;
  }
</style>

<oauth:displayName/>

<c:if test="${empty oauthConnectionBean.connectionId}">
  <tr class="googleNote">
    <td colspan="2">
      <div class="attentionComment">
        <i>This type of connection relies on OAuth 2.0 protocol. It can be used for authenticating Google users in TeamCity.</i>

        <br/>
        <br/>
        Create a new Google project or use an existing one at
        <a href="https://console.cloud.google.com/apis" rel="noreferrer">
          https://console.cloud.google.com/apis</a>.
        <br/><br/>
        Create credentials of <b>OAuth Client ID</b> type. Use <b>Web</b> application type.
        <br/><br/>
        In the "Authorized redirect URIs" field, enter the following redirect URLs:<br/>
        <oauth:urlTable>
          <tr>
            <td>
              <oauth:redirectUrl id="firstGoogleRootUrl" value="${googleRootUrl}" style="width:35em;"/>
            </td>
          </tr>
          <c:if test="${!googleRootUrl.equals(currentGoogleRootUrl)}">
            <tr>
              <td>
                <oauth:redirectUrl id="secondGoogleRootUrl" value="${currentGoogleRootUrl}" style="width:35em;"/>
              </td>
            </tr>
          </c:if>
        </oauth:urlTable>
        <br/>
        Once created, enter the app's <strong>Client ID</strong> | <strong>Client Secret</strong> in the form below.
        <bs:help file="Connections-Google"/><br/>
      </div>
    </td>
  </tr>
</c:if>

<tr>
  <th><label for="${keys.clientId}">Client ID:<l:star/></label></th>
  <td>
    <props:textProperty name="${keys.clientId}" className="longField"/>
    <span class="error" id="error_${keys.clientId}"></span>
  </td>
</tr>

<tr>
  <th><label for="${keys.clientSecret}">Client secret:<l:star/></label></th>
  <td>
    <props:passwordProperty name="${keys.clientSecret}" className="longField"/>
    <span class="error" id="error_${keys.clientSecret}"></span>
  </td>
</tr>
