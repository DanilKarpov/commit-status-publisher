<%@ page import="jetbrains.buildServer.serverSide.oauth.gitlab.GitLabAuthentication" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>
<c:url var="path" value="<%=GitLabAuthentication.GITLAB_LOGIN_CONTROLLER_PATH%>"/>
<a href="${path}" title="Log in with GitLab"><span class="loginIcon_gitlab"/></a>


