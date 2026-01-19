<%@ page import="jetbrains.buildServer.serverSide.oauth.azuredevops.AzureDevOpsAuthentication" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>
<c:url var="path" value="<%=AzureDevOpsAuthentication.LOGIN_CONTROLLER_PATH%>"/>
<a href="${path}" title="Log in with Azure DevOps"><span class="loginIcon_azure"/></a>

