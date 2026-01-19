<%@ page import="jetbrains.buildServer.serverSide.oauth.bitbucket.BitBucketOAuthProvider" %>
<%@ page import="static jetbrains.buildServer.serverSide.oauth.gitlab.GitLabAuthentication.GROUP_KEY" %>
<%@ page import="static jetbrains.buildServer.serverSide.oauth.bitbucket.BitBucketAuthentication.ALLOWED_WORKSPACES_KEY" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="prop" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>

<%--@elvariable id="connection" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor"--%>
<c:set var="connectionType" value="<%=BitBucketOAuthProvider.TYPE%>"/>
<c:url var="oauthConnectionsUrl" value="/admin/editProject.html?projectId=_Root&tab=oauthConnections"/>
<div>
    <c:choose>
        <c:when test="${connection != null}">
            The Bitbucket authentication module uses the <a href="${oauthConnectionsUrl}"><c:out value="${connection.connectionDisplayName}"/>
            connection</a> from the Root project.
        </c:when>
        <c:otherwise>
            Please add the <a href="${oauthConnectionsUrl}#addDialog=${connectionType}">Bitbucket
            connection</a> to the Root project to activate the Bitbucket authentication.
        </c:otherwise>
    </c:choose>
</div>
<br/>
<div><jsp:include page="/admin/allowCreatingNewUsersByLogin.jsp"/></div>
<br/>
<oauth:allowUsersToLogin unitKeysName="<%=ALLOWED_WORKSPACES_KEY%>" msgAllowCheckbox="Disable restricting authentication to specified workspaces"
                         msgRestrictUnits="Restrict authentication to members of the specified Bitbucket workspaces:"
                         msgRestrictionNote="Specify a comma-separated list of allowed workspace IDs"
/>