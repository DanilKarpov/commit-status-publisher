<%@ page import="static jetbrains.buildServer.serverSide.oauth.gitlab.GitLabAuthentication.GROUP_KEY" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.gitlab.GitLabCEorEEOAuthProvider" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="prop" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>

<%--@elvariable id="connection" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor"--%>
<%--@elvariable id="oAuthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthProvider"--%>
<c:set var="connectionType" value="${oAuthProvider.type}"/>
<c:set var="glEType" value="<%=GitLabCEorEEOAuthProvider.TYPE%>"/>
<c:url var="oauthConnectionsUrl" value="/admin/editProject.html?projectId=_Root&tab=oauthConnections"/>
<div>
    <c:choose>
        <c:when test="${connection != null}">
            The ${connection.oauthProvider.displayName} authentication module uses the <a href="${oauthConnectionsUrl}"><c:out value="${connection.connectionDisplayName}"/>
            connection</a> from the Root project.
        </c:when>
        <c:otherwise>
            Please add the <a href="${oauthConnectionsUrl}#addDialog=${oAuthProvider.type}">${oAuthProvider.displayName}
            connection</a> to the Root project to activate the ${oAuthProvider.displayName} authentication.
        </c:otherwise>
    </c:choose>
</div>
<br/>
<div><jsp:include page="/admin/allowCreatingNewUsersByLogin.jsp"/></div>
<br/>
<oauth:allowUsersToLogin unitKeysName="<%=GROUP_KEY%>" msgAllowCheckbox="Disable restricting authentication to specified ${connectionType eq glEType ? 'GitLab CE/EE' : 'GitLab.com'} groups"
                         msgRestrictUnits="Restrict authentication to users from the specified GitLab groups:"
                         msgRestrictionNote="Specify a comma-separated list of allowed group paths, where a group path is the part of a group URL after 'https://gitlab.com/' (e.g. 'teamcity' for 'https://gitlab.com/teamcity')"
/>

