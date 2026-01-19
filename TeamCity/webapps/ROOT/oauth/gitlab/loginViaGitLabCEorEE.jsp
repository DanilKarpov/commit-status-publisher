<%@ page import="jetbrains.buildServer.serverSide.oauth.gitlab.GitLabAuthentication" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>
<c:url var="path" value="<%=GitLabAuthentication.GITLAB_EE_LOGIN_CONTROLLER_PATH%>"/>
<a href="${path}" title="Log in with GitLab CE/EE"><span class="loginIcon_gitlab-enterprise"/></a>


