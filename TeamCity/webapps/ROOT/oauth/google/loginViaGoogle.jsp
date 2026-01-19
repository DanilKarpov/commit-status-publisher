<%@ page import="jetbrains.buildServer.serverSide.oauth.google.GoogleAuthentication" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>
<c:url var="path" value="<%=GoogleAuthentication.LOGIN_CONTROLLER_PATH%>"/>
<a href="${path}" title="Log in with Google"><span class="loginIcon_google"/></a>
