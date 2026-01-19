<%@ page import="jetbrains.buildServer.serverSide.oauth.github.GitHubAuthentication" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>
<c:url var="path" value="<%=GitHubAuthentication.GITHUB_COM_LOGIN_CONTROLLER_PATH%>"/>
<a href="${path}" title="Log in with GitHub"><span class="loginIcon_github"/></a>

