<%@ page import="static jetbrains.buildServer.serverSide.oauth.google.GoogleAuthentication.DOMAINS_KEY" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="prop" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>

<%--@elvariable id="connection" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionDescriptor"--%>
<%--@elvariable id="oAuthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthProvider"--%>
<c:set var="connectionType" value="${oAuthProvider.type}"/>
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

<div>
    <jsp:include page="/admin/allowSkipping2FA.jsp"/>
</div>

<div>
    <jsp:include page="/admin/allowCreatingNewUsersByLogin.jsp"/>
</div>

<br/>

<oauth:allowUsersToLogin unitKeysName="<%=DOMAINS_KEY%>" msgAllowCheckbox="Disable restricting authentication to specified domains"
                         msgAllowCheckboxNote="Allow users from all domains to log in, including <b>gmail.com</b>"
                         msgRestrictUnits="Restrict authentication to users from the specified Google domains:"
                         msgRestrictionNote="Specify a comma-separated list of allowed domains.<br/>For example, <i>company.com,another.com</i>"/>