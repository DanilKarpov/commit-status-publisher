<%@ page import="static jetbrains.buildServer.serverSide.oauth.github.GitHubAuthentication.ORGANIZATION_KEY" %>
<%@ page import="jetbrains.buildServer.serverSide.oauth.github.GHEOAuthProvider" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="prop" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>

<%--@elvariable id="connection" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor"--%>
<%--@elvariable id="oAuthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthProvider"--%>
<c:set var="connectionType" value="${oAuthProvider.type}"/>
<c:set var="gheType" value="<%=GHEOAuthProvider.TYPE%>"/>
<c:url var="oauthConnectionsUrl" value="/admin/editProject.html?projectId=_Root&tab=oauthConnections"/>
<div>
    <c:choose>
        <c:when test="${connection != null}">
            The ${connection.oauthProvider.displayName} authentication module uses the <a href="${oauthConnectionsUrl}"><c:out value="${connection.connectionDisplayName}"/>
            connection</a> from the Root project.
        </c:when>
        <c:otherwise>
            Please add the <a href="${oauthConnectionsUrl}#addDialog=${connectionType}">${oAuthProvider.displayName}
            connection</a> to the Root project to activate the ${oAuthProvider.displayName} authentication.
        </c:otherwise>
    </c:choose>
</div>
<br/>
<div><jsp:include page="/admin/allowCreatingNewUsersByLogin.jsp"/></div>
<br/>
<oauth:allowUsersToLogin unitKeysName="<%=ORGANIZATION_KEY%>" msgAllowCheckbox="Disable restricting authentication to specified ${connectionType eq gheType ? 'GitHub Enterprise' : 'GitHub.com'} organizations"
                         msgRestrictUnits="Restrict authentication to users from the specified GitHub organizations:"
                         msgRestrictionNote="Specify a comma-separated list of allowed organizations.<br/>Make sure that the GitHub OAuth application used in the Root ${connectionType eq gheType ? 'GitHub Enterprise' : 'GitHub.com'} connection is approved for each specified organization"
                         helpFile="Integrating+TeamCity+with+VCS+Hosting+Services#Connecting+to+GitHub"
/>